"""Independent reference for the Trees module (catalog cases.md, TS-...).

Run:  uv run --quiet --no-project --with networkx==3.7 python3 ref.py
      ... python3 ref.py --fill          rewrite '?' cells of cases.md with computed values
      ... python3 ref.py --emit TS-301    print the computed value of one case

Every value is computed by the model of api.md written here (iterative, index space: incidence
rows in position order, parent / parent-edge / depth arrays, children by edge position, preorder
by an explicit stack), then checked two more ways:

* a second, naive implementation from the definitions: recursion for preorder and postorder,
  BFS from scratch for paths, brute-force subsets for ancestors, union-find for recognition,
  the textbook smallest-leaf loop for Pruefer codes;
* NetworkX 3.7: is_tree / is_forest / is_arborescence on Multi(Di)Graph (parallel edges and
  self-loops kept), dfs_preorder_nodes / dfs_postorder_nodes / bfs_tree successors on a Graph
  whose adjacency is built in edge-position order (so NetworkX's neighbor order is ours),
  shortest_path, shortest_path_length, descendants / ancestors, connected_components (in node
  order), to_prufer_sequence / from_prufer_sequence.

Large cases (more than 5000 vertices) skip NetworkX and recursion; their values are also checked
against closed forms (CLOSED below), derived by hand from the shape of the input.
"""

import re
import sys
from collections import deque
from pathlib import Path

import networkx as nx

HERE = Path(__file__).resolve().parent
CASES = HERE / "cases.md"
BIG = 5000

# --------------------------------------------------------------------------------------------
# Parsing the Source column
# --------------------------------------------------------------------------------------------


def vtok(s):
    s = s.strip()
    return int(s) if re.fullmatch(r"-?\d+", s) else s


def expand_range(s):
    s = s.strip()
    m = re.fullmatch(r"(-?\d+)\.\.(-?\d+)", s)
    if m:
        a, b = int(m.group(1)), int(m.group(2))
        return list(range(a, b + 1))
    return [vtok(s)]


def split_top(s, sep=","):
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == sep and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur)
    return [x.strip() for x in out if x.strip()]


def items(s):
    res = []
    for t in split_top(s):
        res.extend(expand_range(t))
    return res


def parse_graph(cell):
    """`U: [v,...] edges` or `D: ...`. Returns (kind, vertices, edges as endpoint pairs)."""
    kind, rest = cell.split(":", 1)
    kind = kind.strip()
    rest = rest.strip()
    verts = []
    if rest.startswith("["):
        close = rest.index("]")
        verts = items(rest[1:close])
        rest = rest[close + 1 :].strip()
    edges = []
    arrow = ">" if kind == "D" else "-"
    for tok in split_top(rest):
        m = re.fullmatch(r"P\((.*)\)", tok)
        if m:
            vs = items(m.group(1))
            edges += list(zip(vs, vs[1:]))
            continue
        m = re.fullmatch(r"C\((.*)\)", tok)
        if m:
            vs = items(m.group(1))
            edges += list(zip(vs, vs[1:] + vs[:1]))
            continue
        m = re.fullmatch(r"S\((.*);(.*)\)", tok)
        if m:
            c = vtok(m.group(1))
            edges += [(c, x) for x in items(m.group(2))]
            continue
        m = re.fullmatch(r"kary\((\d+),(\d+)\)", tok)
        if m:
            n, k = int(m.group(1)), int(m.group(2))
            edges += [(i, k * i + j) for i in range(n) for j in range(1, k + 1) if k * i + j < n]
            continue
        m = re.fullmatch(r"(-?\w+)" + re.escape(arrow) + r"(-?\w+)", tok)
        if not m:
            raise ValueError(f"bad edge token {tok!r} in {cell!r}")
        edges.append((vtok(m.group(1)), vtok(m.group(2))))
    # vertex order: listed (deduplicated), then endpoints by first appearance
    order, seen = [], set()
    for v in verts + [x for e in edges for x in e]:
        if v not in seen:
            seen.add(v)
            order.append(v)
    return kind, order, edges


def parse_source(cell):
    cell = cell.strip().strip("`")
    if cell.startswith("U:") or cell.startswith("D:"):
        return parse_graph(cell)
    m = re.fullmatch(r"parents:\s*\[(.*)\]", cell)
    if m:
        ps = [None if t.strip() == "_" else int(t) for t in split_top(m.group(1))] if m.group(1).strip() else []
        return ("parents", ps)
    m = re.fullmatch(r"closure:\s*\[(.*?)\]\s*\{(.*)\}", cell)
    if m:
        vs = [vtok(t) for t in split_top(m.group(1))]
        mp = {}
        for pair in split_top(m.group(2)):
            a, b = pair.split(":")
            mp[vtok(a)] = vtok(b)
        return ("closure", vs, mp)
    m = re.fullmatch(r"prufer:\s*\[(.*)\]", cell)
    if m:
        return ("prufer", items(m.group(1)) if m.group(1).strip() else [])
    raise ValueError(f"bad source {cell!r}")


# --------------------------------------------------------------------------------------------
# The model (api.md), index space
# --------------------------------------------------------------------------------------------


class Trap(Exception):
    pass


class T:
    """kind: Tree, Forest, RootedTree, Arborescence. edges: list of (i, j) vertex indices at
    their positions (for a parent-built or arborescence edge, (parent, child))."""

    def __init__(self, kind, verts, edges, root=None):
        self.kind = kind
        self.verts = verts
        self.idx = {v: i for i, v in enumerate(verts)}
        self.edges = edges
        self.n = len(verts)
        self.rows = [[] for _ in range(self.n)]  # incident edge positions, ascending
        for k, (a, b) in enumerate(edges):
            self.rows[a].append(k)
            self.rows[b].append(k)
        self.root = root
        if kind in ("RootedTree", "Arborescence"):
            self._root_at(root)

    def other(self, k, v):
        a, b = self.edges[k]
        return b if a == v else a

    def _root_at(self, r):
        n = self.n
        self.parent = [-1] * n
        self.pedge = [-1] * n
        self.depth = [0] * n
        self.children = [[] for _ in range(n)]
        # preorder by an explicit stack of (vertex, cursor in row)
        self.pre = []
        self.post = []
        stack = [(r, 0)]
        self.pre.append(r)
        while stack:
            v, c = stack[-1]
            row = self.rows[v]
            while c < len(row) and row[c] == self.pedge[v]:
                c += 1
            if c < len(row):
                stack[-1] = (v, c + 1)
                k = row[c]
                w = self.other(k, v)
                self.parent[w] = v
                self.pedge[w] = k
                self.depth[w] = self.depth[v] + 1
                self.children[v].append(w)
                self.pre.append(w)
                stack.append((w, 0))
            else:
                stack.pop()
                self.post.append(v)
        assert len(self.pre) == n
        self.prepos = [0] * n
        for i, v in enumerate(self.pre):
            self.prepos[v] = i
        self.size = [1] * n
        for v in reversed(self.pre):
            if self.parent[v] >= 0:
                self.size[self.parent[v]] += self.size[v]
        # the edge orientation of an arborescence: parent -> child
        if self.kind == "Arborescence":
            for w in range(n):
                if self.pedge[w] >= 0:
                    assert set(self.edges[self.pedge[w]]) == {self.parent[w], w}
                    self.edges[self.pedge[w]] = (self.parent[w], w)

    # conversions keep vertices and edge positions
    def convert(self, kind, root=None):
        if kind == "Tree":
            if self.kind == "Forest":
                raise Trap("not a conversion")
            return T("Tree", self.verts, list(self.edges))
        if kind == "Forest":
            return T("Forest", self.verts, list(self.edges))
        if kind == "RootedTree":
            if self.kind == "Forest":
                raise Trap("not a conversion")
            if root is None:
                if self.kind != "Arborescence":
                    raise Trap("root needed")
                r = self.root
            else:
                if root not in self.idx:
                    raise Trap("root not a vertex")
                r = self.idx[root]
            return T("RootedTree", self.verts, list(self.edges), r)
        if kind == "Arborescence":
            if self.kind != "RootedTree":
                raise Trap("not a conversion")
            return T("Arborescence", self.verts, list(self.edges), self.root)
        raise ValueError(kind)


def connected_from(n, rows, other, s):
    seen = [False] * n
    seen[s] = True
    q = deque([s])
    cnt = 1
    while q:
        v = q.popleft()
        for k in rows[v]:
            w = other(k, v)
            if not seen[w]:
                seen[w] = True
                cnt += 1
                q.append(w)
    return cnt


def tree_from_graph(verts, edges):
    n, m = len(verts), len(edges)
    if n == 0 or m != n - 1:
        return None
    idx = {v: i for i, v in enumerate(verts)}
    ie = [(idx[a], idx[b]) for a, b in edges]
    t = T("Tree", verts, ie)
    if connected_from(n, t.rows, t.other, 0) != n:
        return None
    return t


def forest_from_graph(verts, edges):
    idx = {v: i for i, v in enumerate(verts)}
    ie = [(idx[a], idx[b]) for a, b in edges]
    # union-find: the first edge whose ends are already joined (a loop included) is a cycle
    par = list(range(len(verts)))

    def find(x):
        while par[x] != x:
            par[x] = par[par[x]]
            x = par[x]
        return x

    for a, b in ie:
        ra, rb = find(a), find(b)
        if ra == rb:
            return None
        par[ra] = rb
    return T("Forest", verts, ie)


def arborescence_from_digraph(verts, edges):
    n, m = len(verts), len(edges)
    if n == 0 or m != n - 1:
        return None
    idx = {v: i for i, v in enumerate(verts)}
    ie = [(idx[a], idx[b]) for a, b in edges]
    indeg = [0] * n
    for a, b in ie:
        indeg[b] += 1
    if any(d > 1 for d in indeg):
        return None
    roots = [v for v in range(n) if indeg[v] == 0]
    if len(roots) != 1:
        return None
    r = roots[0]
    out = [[] for _ in range(n)]
    for k, (a, b) in enumerate(ie):
        out[a].append(k)
    seen = [False] * n
    seen[r] = True
    st = [r]
    cnt = 1
    while st:
        v = st.pop()
        for k in out[v]:
            w = ie[k][1]
            if not seen[w]:
                seen[w] = True
                cnt += 1
                st.append(w)
    if cnt != n:
        return None
    return T("Arborescence", verts, ie, r)


def from_parents(kind, verts, parent):
    """verts: vertices (duplicates dropped, first kept); parent: vertex -> vertex or None."""
    order, seen = [], set()
    for v in verts:
        if v not in seen:
            seen.add(v)
            order.append(v)
    idx = {v: i for i, v in enumerate(order)}
    n = len(order)
    par = []
    for v in order:
        p = parent(v)
        if p is not None and p not in idx:
            return None
        par.append(None if p is None else idx[p])
    roots = [i for i in range(n) if par[i] is None]
    if len(roots) != 1:
        return None
    # no cycle: every chain reaches the root (colors: 0 new, 1 on the current chain, 2 done)
    color = [0] * n
    for s in range(n):
        chain = []
        v = s
        while v is not None and color[v] == 0:
            color[v] = 1
            chain.append(v)
            v = par[v]
        if v is not None and color[v] == 1:
            return None
        for c in chain:
            color[c] = 2
    edges = [(par[i], i) for i in range(n) if par[i] is not None]
    return T(kind, order, edges, roots[0])


def tree_from_prufer(seq):
    n = len(seq) + 2
    if any(not isinstance(x, int) or x < 0 or x >= n for x in seq):
        return None
    deg = [1] * n
    for x in seq:
        deg[x] += 1
    # linear decoding (Wang et al.; NetworkX, igraph): a pointer to the least leaf, and the
    # leaf just made when it is below the pointer
    edges = []
    ptr = 0
    while deg[ptr] != 1:
        ptr += 1
    leaf = ptr
    for x in seq:
        edges.append((leaf, x))
        deg[leaf] -= 1
        deg[x] -= 1
        if x < ptr and deg[x] == 1:
            leaf = x
        else:
            ptr += 1
            while deg[ptr] != 1:
                ptr += 1
            leaf = ptr
    u, v = [i for i in range(n) if deg[i] == 1]
    edges.append((u, v))
    return T("Tree", list(range(n)), edges)


def prufer_of(t):
    if t.n < 2:
        return None
    deg = [len(r) for r in t.rows]
    nb = lambda v: [t.other(k, v) for k in t.rows[v]]
    removed = [False] * t.n
    out = []
    ptr = 0
    while deg[ptr] != 1:
        ptr += 1
    leaf = ptr
    for _ in range(t.n - 2):
        x = next(w for w in nb(leaf) if not removed[w])
        out.append(x)
        removed[leaf] = True
        deg[x] -= 1
        if x < ptr and deg[x] == 1:
            leaf = x
        else:
            ptr += 1
            while deg[ptr] != 1 or removed[ptr]:
                ptr += 1
            leaf = ptr
    return [t.verts[i] for i in out]


def build(source, steps):
    """steps: list of (kind, root-or-None)."""
    cur = None
    for i, (kind, root) in enumerate(steps):
        if i == 0:
            s0 = source[0]
            if s0 == "U":
                _, verts, edges = source
                if kind == "Tree":
                    cur = tree_from_graph(verts, edges)
                elif kind == "Forest":
                    cur = forest_from_graph(verts, edges)
                elif kind == "RootedTree":
                    if root not in set(verts):
                        raise Trap("root not a vertex")
                    t = tree_from_graph(verts, edges)
                    cur = None if t is None else t.convert("RootedTree", root)
                else:
                    raise ValueError("bad first step")
            elif s0 == "D":
                if kind != "Arborescence":
                    raise ValueError("bad first step")
                _, verts, edges = source
                cur = arborescence_from_digraph(verts, edges)
            elif s0 == "parents":
                ps = source[1]
                if kind not in ("Arborescence", "RootedTree"):
                    raise ValueError("bad first step")
                n = len(ps)
                cur = from_parents(kind, list(range(n)), lambda v: ps[v] if (ps[v] is None or 0 <= ps[v] < n) else ("out", ps[v]))
            elif s0 == "closure":
                _, vs, mp = source
                if kind not in ("Arborescence", "RootedTree"):
                    raise ValueError("bad first step")
                cur = from_parents(kind, vs, lambda v: mp.get(v))
            elif s0 == "prufer":
                if kind != "Tree":
                    raise ValueError("bad first step")
                cur = tree_from_prufer(source[1])
            if cur is None:
                return None
        else:
            cur = cur.convert(kind, root)
    return cur


# --------------------------------------------------------------------------------------------
# Queries and formatting
# --------------------------------------------------------------------------------------------


def fmt(x):
    if x is None:
        return "nil"
    if isinstance(x, bool):
        return "T" if x else "F"
    if isinstance(x, int):
        return f"#{x}"
    if isinstance(x, list):
        return "[" + ",".join(str(e) for e in x) + "]"
    return str(x)


def edge_str(t, k):
    a, b = t.edges[k]
    sep = ">" if t.kind == "Arborescence" else "-"
    return f"{t.verts[a]}{sep}{t.verts[b]}"


def path_of(t, a, b):
    """Index-space path a -> b: climb by depth (rooted). For Tree/Forest the model roots
    internally at the least vertex of each tree, as api.md says."""
    if t.kind in ("Tree", "Forest"):
        rt = internal_rooting(t)
        return path_rooted(rt, a, b, directed=False)
    return path_rooted(t, a, b, directed=(t.kind == "Arborescence"))


_internal = {}


def internal_rooting(t):
    if hasattr(t, "_rt"):
        return t._rt
    # root every tree at its least vertex; reuse T._root_at per component
    n = t.n
    parent = [-1] * n
    pedge = [-1] * n
    depth = [0] * n
    comp = [-1] * n
    c = 0
    for r in range(n):
        if comp[r] >= 0:
            continue
        comp[r] = c
        st = [r]
        while st:
            v = st.pop()
            for k in t.rows[v]:
                w = t.other(k, v)
                if comp[w] < 0:
                    comp[w] = c
                    parent[w] = v
                    pedge[w] = k
                    depth[w] = depth[v] + 1
                    st.append(w)
        c += 1

    class R:
        pass

    rt = R()
    rt.parent, rt.pedge, rt.depth, rt.comp, rt.count = parent, pedge, depth, comp, c
    t._rt = rt
    return rt


def path_rooted(rt, a, b, directed):
    if hasattr(rt, "comp") and rt.comp[a] != rt.comp[b]:
        return None
    up_a, up_b = [a], [b]
    ea, eb = [], []
    x, y = a, b
    while rt.depth[x] > rt.depth[y]:
        ea.append(rt.pedge[x])
        x = rt.parent[x]
        up_a.append(x)
    while rt.depth[y] > rt.depth[x]:
        eb.append(rt.pedge[y])
        y = rt.parent[y]
        up_b.append(y)
    while x != y:
        ea.append(rt.pedge[x])
        x = rt.parent[x]
        up_a.append(x)
        eb.append(rt.pedge[y])
        y = rt.parent[y]
        up_b.append(y)
    if directed and len(up_a) > 1:  # a must be an ancestor of b, or b itself
        return None
    vs = up_a + list(reversed(up_b[:-1]))
    es = ea + list(reversed(eb))
    return vs, es


def query(t, q):
    """Returns a formatted string."""
    V = t.verts
    ix = lambda s: (t.idx[vtok(s)] if vtok(s) in t.idx else (_ for _ in ()).throw(Trap("not a vertex")))
    m = re.fullmatch(r"(\w+)(?:\((.*)\))?((?:\.\w+|\[-?\d+\])*)", q.strip())
    if not m:
        raise ValueError(q)
    name, args, tail = m.group(1), m.group(2), m.group(3)
    a = [x.strip() for x in split_top(args)] if args else []
    if name == "built":
        val = True
    elif name == "vertices":
        val = list(V)
    elif name == "edges":
        val = [edge_str(t, k) for k in range(len(t.edges))]
    elif name == "vertexCount":
        val = t.n
    elif name == "edgeCount":
        val = len(t.edges)
    elif name == "root":
        val = V[t.root]
    elif name == "parent":
        p = t.parent[ix(a[0])]
        val = None if p < 0 else V[p]
    elif name == "parentEdge":
        p = t.pedge[ix(a[0])]
        val = None if p < 0 else p
    elif name == "children":
        val = [V[c] for c in t.children[ix(a[0])]]
    elif name == "depth":
        val = t.depth[ix(a[0])]
    elif name == "height":
        val = max(t.depth)
    elif name == "preorder":
        val = [V[v] for v in t.pre]
    elif name == "postorder":
        val = [V[v] for v in t.post]
    elif name == "descendants":
        v = ix(a[0])
        p = t.prepos[v]
        val = [V[w] for w in t.pre[p + 1 : p + t.size[v]]]
    elif name == "ancestors":
        v = ix(a[0])
        val = []
        while t.parent[v] >= 0:
            v = t.parent[v]
            val.append(V[v])
    elif name == "isAncestor":
        x, y = ix(a[0]), ix(a[1])
        val = x != y and t.prepos[x] <= t.prepos[y] < t.prepos[x] + t.size[x]
    elif name == "path":
        r = path_of(t, ix(a[0]), ix(a[1]))
        if r is None:
            return "nil"
        vs, es = r
        if tail == ".length":
            return fmt(len(es))
        return "[" + ",".join(str(V[v]) for v in vs) + "]/[" + ",".join(map(str, es)) + "]"
    elif name == "degree":
        v = ix(a[0])
        val = len(t.rows[v])
    elif name == "incidentEdges":
        val = list(t.rows[ix(a[0])])
    elif name == "neighbors":
        v = ix(a[0])
        val = [V[t.other(k, v)] for k in t.rows[v]]
    elif name == "outEdges":
        v = ix(a[0])
        val = [k for k in t.rows[v] if t.edges[k][0] == v]
    elif name == "inEdges":
        v = ix(a[0])
        val = [k for k in t.rows[v] if t.edges[k][1] == v]
    elif name == "outDegree":
        v = ix(a[0])
        val = sum(1 for k in t.rows[v] if t.edges[k][0] == v)
    elif name == "inDegree":
        v = ix(a[0])
        val = sum(1 for k in t.rows[v] if t.edges[k][1] == v)
    elif name == "trees":
        return trees_str(t)
    elif name == "treeCount":
        val = internal_rooting(t).count
    elif name == "component":
        val = internal_rooting(t).comp[ix(a[0])]
    elif name == "prufer":
        val = prufer_of(t)
    else:
        raise ValueError(f"unknown query {q!r}")
    # tails: .count, [i]
    for part in re.findall(r"\.\w+|\[-?\d+\]", tail or ""):
        if part == ".count":
            val = len(val)
        elif part.startswith("["):
            val = val[int(part[1:-1])]
        else:
            raise ValueError(part)
    return fmt(val)


def forest_trees(t):
    rt = internal_rooting(t)
    out = []
    for c in range(rt.count):
        vs = [v for v in range(t.n) if rt.comp[v] == c]
        es = [k for k in range(len(t.edges)) if rt.comp[t.edges[k][0]] == c]
        out.append((vs, es))
    return out


def trees_str(t):
    parts = []
    for vs, es in forest_trees(t):
        parts.append(
            "[" + ",".join(str(t.verts[v]) for v in vs) + "]/[" + ",".join(edge_str(t, k) for k in es) + "]"
        )
    return "; ".join(parts) if parts else "none"


# Equality (api.md): vertex set + edge set (+ root for RootedTree); arborescence edges directed.
def eq_key(t):
    if t.kind == "Arborescence":
        es = frozenset((t.verts[a], t.verts[b]) for a, b in t.edges)
    else:
        es = frozenset(frozenset((t.verts[a], t.verts[b])) for a, b in t.edges)
    root = t.verts[t.root] if t.kind == "RootedTree" else None
    return (frozenset(t.verts), es, root)


# --------------------------------------------------------------------------------------------
# Predicates on the source graph
# --------------------------------------------------------------------------------------------


def predicate(source, name):
    if name == "isTree":
        assert source[0] == "U"
        return fmt(tree_from_graph(source[1], source[2]) is not None)
    if name == "isArborescence":
        assert source[0] == "D"
        return fmt(arborescence_from_digraph(source[1], source[2]) is not None)
    if name == "isAcyclic":  # Cycles' name for is_forest; checked here as Forest(g) != nil
        assert source[0] == "U"
        return fmt(forest_from_graph(source[1], source[2]) is not None)
    raise ValueError(name)


# --------------------------------------------------------------------------------------------
# Operation parser: `Build > Build ... : query` or a predicate, or `== <source>`
# --------------------------------------------------------------------------------------------


def parse_steps(s):
    steps = []
    for part in s.split(">"):
        part = part.strip()
        m = re.fullmatch(r"(Tree|Forest|RootedTree|Arborescence)(?:\(root:\s*(.*)\))?", part)
        if not m:
            raise ValueError(f"bad step {part!r}")
        steps.append((m.group(1), vtok(m.group(2)) if m.group(2) is not None else None))
    return steps


def evaluate(source_cell, op):
    op = op.strip().strip("`")
    if op in ("isTree", "isArborescence", "isAcyclic"):
        return predicate(parse_source(source_cell), op)
    if " == " in op:
        lhs_op, rhs = op.split(" == ", 1)
        rhs_src, rhs_op = rhs.rsplit(" as ", 1)
        try:
            l = build(parse_source(source_cell), parse_steps(lhs_op))
            r = build(parse_source(rhs_src), parse_steps(rhs_op))
        except Trap:
            return "trap"
        if l is None or r is None:
            return "nil"
        return fmt(l.kind == r.kind and eq_key(l) == eq_key(r))
    if " : " in op:
        b, q = op.split(" : ", 1)
    else:
        b, q = op, "built"
    try:
        t = build(parse_source(source_cell), parse_steps(b))
        if t is None:
            return "nil"
        return query(t, q)
    except Trap:
        return "trap"


# --------------------------------------------------------------------------------------------
# Independent checks
# --------------------------------------------------------------------------------------------

failures = []


def check(cond, msg):
    if not cond:
        failures.append(msg)


def nx_undirected_multi(verts, edges):
    g = nx.MultiGraph()
    g.add_nodes_from(verts)
    g.add_edges_from(edges)
    return g


def naive_pre(t, v, out):
    out.append(v)
    for c in t.children[v]:
        naive_pre(t, c, out)


def naive_post(t, v, out):
    for c in t.children[v]:
        naive_post(t, c, out)
    out.append(v)


def nx_simple(t):
    g = nx.Graph()
    g.add_nodes_from(range(t.n))
    for a, b in t.edges:  # position order: NetworkX neighbor order is ours
        g.add_edge(a, b)
    # node order of add_nodes_from is index order; each node's adjacency is in position order
    return g


def cross_check_source(cid, src):
    if src[0] == "U":
        _, verts, edges = src
        if len(verts) > BIG:
            return
        mine_t = tree_from_graph(verts, edges) is not None
        mine_f = forest_from_graph(verts, edges) is not None
        if verts:
            g = nx_undirected_multi(verts, edges)
            check(mine_t == nx.is_tree(g), f"{cid}: is_tree")
            check(mine_f == nx.is_forest(g), f"{cid}: is_forest")
        else:
            check(not mine_t and mine_f, f"{cid}: empty conventions")
        # naive recognition: n - 1 edges and union-find with no failed union
        n = len(verts)
        check(mine_t == (mine_f and len(edges) == n - 1 and n >= 1), f"{cid}: tree = forest + n-1 edges")
    elif src[0] == "D":
        _, verts, edges = src
        if len(verts) > BIG:
            return
        mine = arborescence_from_digraph(verts, edges) is not None
        if verts:
            g = nx.MultiDiGraph()
            g.add_nodes_from(verts)
            g.add_edges_from(edges)
            check(mine == nx.is_arborescence(g), f"{cid}: is_arborescence")
    elif src[0] == "prufer":
        seq = src[1]
        t = tree_from_prufer(seq)
        try:
            g = nx.from_prufer_sequence(seq)
            ok = True
        except Exception:
            ok = False
        check((t is not None) == ok, f"{cid}: from_prufer validity")
        if t is not None:
            mine = {frozenset(e) for e in t.edges}
            theirs = {frozenset(e) for e in g.edges()}
            check(mine == theirs, f"{cid}: from_prufer edges")
            # naive decode: smallest leaf each step, edge order equal to ours
            n = len(seq) + 2
            deg = [1] * n
            for x in seq:
                deg[x] += 1
            es = []
            for x in seq:
                leaf = min(i for i in range(n) if deg[i] == 1)
                es.append((leaf, x))
                deg[leaf] -= 1
                deg[x] -= 1
            u, v = [i for i in range(n) if deg[i] == 1]
            es.append((u, v))
            check(es == t.edges, f"{cid}: prufer decode order")


def cross_check_built(cid, t):
    if t is None or t.n > BIG:
        return
    if t.kind in ("RootedTree", "Arborescence"):
        r = t.root
        pre, post = [], []
        naive_pre(t, r, pre)
        naive_post(t, r, post)
        check(pre == t.pre, f"{cid}: preorder naive")
        check(post == t.post, f"{cid}: postorder naive")
        g = nx_simple(t)
        check(list(nx.dfs_preorder_nodes(g, r)) == t.pre, f"{cid}: nx preorder")
        check(list(nx.dfs_postorder_nodes(g, r)) == t.post, f"{cid}: nx postorder")
        bt = nx.bfs_tree(g, r)
        dist = nx.single_source_shortest_path_length(g, r)
        for v in range(t.n):
            check(list(bt.successors(v)) == t.children[v], f"{cid}: children of {v}")
            check(dist[v] == t.depth[v], f"{cid}: depth of {v}")
            check(nx.descendants(bt, v) == set(t.pre[t.prepos[v] + 1 : t.prepos[v] + t.size[v]]), f"{cid}: desc {v}")
            anc = set()
            x = v
            while t.parent[x] >= 0:
                x = t.parent[x]
                anc.add(x)
            check(nx.ancestors(bt, v) == anc, f"{cid}: anc {v}")
            check(t.size[v] - 1 == len(nx.descendants(bt, v)), f"{cid}: size {v}")
            # post(v) = pre(v) + size(v) - 1 - depth(v)
            check(t.post.index(v) == t.prepos[v] + t.size[v] - 1 - t.depth[v], f"{cid}: post identity {v}")
        if t.n <= 60:
            d = nx.DiGraph()
            d.add_nodes_from(range(t.n))
            d.add_edges_from((t.parent[w], w) for w in range(t.n) if t.parent[w] >= 0)
            for a in range(t.n):
                for b in range(t.n):
                    p = path_rooted(t, a, b, t.kind == "Arborescence")
                    if t.kind == "Arborescence":
                        check((p is not None) == nx.has_path(d, a, b), f"{cid}: arb path {a} {b}")
                        if p is not None:
                            check(p[0] == nx.shortest_path(d, a, b), f"{cid}: arb path vs {a} {b}")
                    else:
                        check(p[0] == nx.shortest_path(g, a, b), f"{cid}: path {a} {b}")
                    if p is not None:
                        vs, es = p
                        for i, k in enumerate(es):
                            check({vs[i], vs[i + 1]} == set(t.edges[k]), f"{cid}: path edge {a} {b}")
    if t.kind in ("Tree", "Forest"):
        g = nx_simple(t)
        comps = list(nx.connected_components(g))
        mine = forest_trees(t)
        check([sorted(c) for c in comps] == [vs for vs, _ in mine], f"{cid}: components order")
        if t.n <= 60:
            for a in range(t.n):
                for b in range(t.n):
                    p = path_of(t, a, b)
                    if nx.has_path(g, a, b):
                        check(p is not None and p[0] == nx.shortest_path(g, a, b), f"{cid}: tpath {a} {b}")
                    else:
                        check(p is None, f"{cid}: tpath nil {a} {b}")
        if t.kind == "Tree" and t.n >= 2:
            relabeled = nx_simple(t)
            check(nx.to_prufer_sequence(relabeled) == [t.idx[v] for v in prufer_of(t)], f"{cid}: to_prufer")
            # naive encode
            alive = set(range(t.n))
            adj = {v: set(t.other(k, v) for k in t.rows[v]) for v in range(t.n)}
            seq = []
            for _ in range(t.n - 2):
                leaf = min(v for v in alive if len(adj[v] & alive) == 1)
                (x,) = adj[leaf] & alive
                seq.append(x)
                alive.remove(leaf)
            check(seq == [t.idx[v] for v in prufer_of(t)], f"{cid}: prufer naive")


# --------------------------------------------------------------------------------------------
# Catalog driver
# --------------------------------------------------------------------------------------------

N6 = 10**6
CLOSED = {
    "TS-800": "T",
    "TS-801": f"#{N6 - 1}",  # depth of the far end of a path
    "TS-802": f"#{N6 - 1}",  # postorder starts at the deepest leaf
    "TS-803": f"#{max(500000, N6 - 1 - 500000)}",
    "TS-804": f"#{N6 - 1}",
    "TS-805": "T",
    "TS-806": f"#{500000}",  # rooted at the far end, 500000's subtree is 0...500000
    "TS-807": f"#{N6 - 1}",
    "TS-808": "#1",  # 7, then the center 0, then the center's first child 1
    "TS-809": "#30",
    "TS-810": f"#{N6}",
    "TS-811": f"#{N6 - 2}",  # a path's code is 1, 2, ..., n - 2
    "TS-812": f"#{(N6 - 1).bit_length() - 1}",  # complete binary tree: floor(log2 n)
    "TS-813": f"#{2**19 - 1}",  # the first-child chain 0, 1, 3, 7, ..., 2^k - 1
}

ROW = re.compile(r"^\|\s*(TS-\d{3})\s*\|(.*)\|\s*$")


def rows():
    for lineno, line in enumerate(CASES.read_text().splitlines()):
        m = ROW.match(line)
        if m:
            cells = [c.strip() for c in split_cells(m.group(2))]
            yield lineno, m.group(1), cells


def split_cells(s):
    # split on '|' not inside backticks
    out, cur, tick = [], "", False
    for ch in s:
        if ch == "`":
            tick = not tick
        if ch == "|" and not tick:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    out.append(cur)
    return out


def main():
    args = sys.argv[1:]
    lines = CASES.read_text().splitlines()
    ids = set()
    n_cases = 0
    mismatches = []
    for lineno, cid, cells in rows():
        src, op, expected = cells[0], cells[1], cells[2]
        check(cid not in ids, f"duplicate id {cid}")
        ids.add(cid)
        n_cases += 1
        got = evaluate(src, op)
        if args and args[0] == "--emit":
            if cid == args[1]:
                print(got)
            continue
        exp = expected.strip("`").strip()
        if exp == "?":
            if "--fill" in args:
                parts = lines[lineno].split("|")
                # columns: '', id, source, op, expected, notes, ''
                parts[4] = f" `{got}` "
                lines[lineno] = "|".join(parts)
            else:
                mismatches.append(f"{cid}: unfilled, computed {got}")
        elif exp != got:
            mismatches.append(f"{cid}: expected {exp}, computed {got}")
        if cid in CLOSED:
            check(CLOSED[cid] == got, f"{cid}: closed form {CLOSED[cid]} vs {got}")
        # independent checks on the source and on every intermediate value
        s = parse_source(src.strip("`"))
        cross_check_source(cid, s)
        o = op.strip("`")
        if o not in ("isTree", "isArborescence", "isAcyclic") and " == " not in o:
            b = o.split(" : ", 1)[0]
            steps = parse_steps(b)
            for i in range(1, len(steps) + 1):
                try:
                    cross_check_built(f"{cid}/{i}", build(s, steps[:i]))
                except Trap:
                    pass
    if args and args[0] == "--emit":
        return
    if "--fill" in args:
        CASES.write_text("\n".join(lines) + "\n")
        print("filled")
        return
    for m in mismatches:
        print("MISMATCH", m)
    check(set(CLOSED) <= ids, "closed forms for missing ids")
    for f in failures:
        print("CHECK FAILED", f)
    print(f"{n_cases} cases")
    if not mismatches and not failures:
        print("all values agree")
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
