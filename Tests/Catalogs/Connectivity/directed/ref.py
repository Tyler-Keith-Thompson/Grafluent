"""Independent reference for the Connectivity catalog (directed graphs only).

Representations are modelled by two things: the `vertices` order and the successor lists.
  ascending(f)  -> AdjacencyMatrix / CompressedSparseRow: vertices sorted, successors sorted, deduplicated
  written(f)    -> the Multigraph test conformer: listed vertices then endpoints by first appearance,
                   successors in written order with repeats
Every algorithm here is iterative.
"""
from collections import deque


def ascending(f):
    V = sorted(set(f['listed']) | {x for e in f['edges'] for x in e})
    S = {v: [] for v in V}
    for u, v in sorted(set(f['edges'])):
        S[u].append(v)
    return V, S


def written(f):
    V = []
    seen = set()
    for v in list(f['listed']) + [x for e in f['edges'] for x in e]:
        if v not in seen:
            seen.add(v); V.append(v)
    S = {v: [] for v in V}
    for u, v in f['edges']:
        S[u].append(v)
    return V, S


def preds_of(V, S):
    P = {v: [] for v in V}
    for u in V:
        for w in S[u]:
            P[w].append(u)
    return P


# ---------------------------------------------------------------- strong components
def tarjan(V, S):
    """Tarjan (1972), iterative. Components in completion order (reverse topological order of the
    condensation). Each component is returned twice: in `vertices` order, and in stack order
    (discovery order, root first)."""
    index, low, on = {}, {}, set()
    stack, comps, counter = [], [], 0
    for r in V:
        if r in index:
            continue
        index[r] = low[r] = counter; counter += 1
        stack.append(r); on.add(r)
        work = [(r, iter(S[r]))]
        while work:
            v, it = work[-1]
            descended = False
            for w in it:
                if w not in index:
                    index[w] = low[w] = counter; counter += 1
                    stack.append(w); on.add(w)
                    work.append((w, iter(S[w])))
                    descended = True
                    break
                if w in on and index[w] < low[v]:
                    low[v] = index[w]
            if descended:
                continue
            work.pop()
            if work:
                p = work[-1][0]
                if low[v] < low[p]:
                    low[p] = low[v]
            if low[v] == index[v]:
                k = len(stack) - 1
                while stack[k] != v:
                    k -= 1
                comp = stack[k:]
                del stack[k:]
                for w in comp:
                    on.discard(w)
                comps.append(comp)
    pos = {v: i for i, v in enumerate(V)}
    return [sorted(c, key=pos.get) for c in comps], comps


def kosaraju(V, S):
    """Kosaraju–Sharir as Boost/CLRS: DFS on G for finish order, then DFS on G^T in decreasing
    finish order. Gives a *topological* order of components (sources first); reversed below to
    compare with Tarjan as sets."""
    P = preds_of(V, S)
    seen, finish = set(), []
    for r in V:
        if r in seen:
            continue
        seen.add(r)
        work = [(r, iter(S[r]))]
        while work:
            v, it = work[-1]
            for w in it:
                if w not in seen:
                    seen.add(w); work.append((w, iter(S[w]))); break
            else:
                work.pop(); finish.append(v)
    comp_of, comps = {}, []
    for r in reversed(finish):
        if r in comp_of:
            continue
        c = [r]; comp_of[r] = len(comps); st = [r]
        while st:
            v = st.pop()
            for u in P[v]:
                if u not in comp_of:
                    comp_of[u] = len(comps); c.append(u); st.append(u)
        comps.append(c)
    return comps


def labels(comps):
    return {v: i for i, c in enumerate(comps) for v in c}


def condensation(V, S, comps):
    lab = labels(comps)
    rows = [set() for _ in comps]
    for u in V:
        for w in S[u]:
            if lab[u] != lab[w]:
                rows[lab[u]].add(lab[w])
    return [sorted(r) for r in rows]


def attracting(V, S, comps):
    rows = condensation(V, S, comps)
    return [c for c, r in zip(comps, rows) if not r]


# ---------------------------------------------------------------- weak components
def weak(V, S):
    """Union–find; components ordered by their first vertex in `vertices` order, members in
    `vertices` order. Equivalent to NetworkX's BFS order of discovery of new components."""
    parent = {v: v for v in V}

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x
    for u in V:
        for w in S[u]:
            a, b = find(u), find(w)
            if a != b:
                parent[a] = b
    order, groups = [], {}
    for v in V:
        r = find(v)
        if r not in groups:
            groups[r] = []; order.append(r)
        groups[r].append(v)
    return [groups[r] for r in order]


# ---------------------------------------------------------------- reachability helpers
def reach(S, s, removed=None):
    seen = {s}; q = deque([s])
    if removed == s:
        return set()
    while q:
        v = q.popleft()
        for w in S[v]:
            if w != removed and w not in seen:
                seen.add(w); q.append(w)
    return seen


# ---------------------------------------------------------------- dominators
def dominators_brute(V, S, r):
    """dom(v) = {u : removing u disconnects v from r} ∪ {v}. Returns (dom sets, idom)."""
    R = reach(S, r)
    dom = {v: {v, r} for v in R}
    for u in R:
        if u == r:
            continue
        cut = reach(S, r, removed=u)
        for v in R:
            if v not in cut:
                dom[v].add(u)
    idom = {}
    for v in R:
        if v == r:
            continue
        strict = dom[v] - {v}
        # the strict dominator dominated by all the others has the most dominators
        idom[v] = max(strict, key=lambda d: len(dom[d]))
    return dom, idom


def dfs_preorder_postorder(S, r):
    pre, post, parent = [r], [], {r: None}
    work = [(r, iter(S[r]))]
    while work:
        v, it = work[-1]
        for w in it:
            if w not in parent:
                parent[w] = v; pre.append(w); work.append((w, iter(S[w]))); break
        else:
            work.pop(); post.append(v)
    return pre, post, parent


def chk(V, S, r):
    """Cooper, Harvey and Kennedy (2001), as NetworkX: reverse postorder of a DFS from r."""
    pre, post, _ = dfs_preorder_postorder(S, r)
    po = {v: i for i, v in enumerate(post)}
    P = preds_of(V, S)
    idom = {r: r}
    order = list(reversed(post))[1:]

    def intersect(a, b):
        while a != b:
            while po[a] < po[b]:
                a = idom[a]
            while po[b] < po[a]:
                b = idom[b]
        return a
    changed = True
    rounds = 0
    while changed:
        changed = False; rounds += 1
        for v in order:
            new = None
            for p in P[v]:
                if p in idom:
                    new = p if new is None else intersect(p, new)
            if idom.get(v) != new:
                idom[v] = new; changed = True
    del idom[r]
    return idom, rounds


def lengauer_tarjan(V, S, r):
    """Lengauer–Tarjan (1979), simple version (path compression, no balancing), with an
    iterative COMPRESS so a 100 000-vertex chain does not recurse."""
    pre, _, parent = dfs_preorder_postorder(S, r)
    n = len(pre)
    num = {v: i for i, v in enumerate(pre)}
    par = [num[parent[v]] if parent[v] is not None else -1 for v in pre]
    P = preds_of(V, S)
    pred = [[num[u] for u in P[v] if u in num] for v in pre]
    semi = list(range(n)); label = list(range(n)); anc = [-1] * n
    idom = [-1] * n; bucket = [[] for _ in range(n)]

    def eval_(v):
        if anc[v] == -1:
            return v
        # COMPRESS, iteratively: walk up to the last vertex whose ancestor is linked
        path = []
        x = v
        while anc[anc[x]] != -1:
            path.append(x); x = anc[x]
        for y in reversed(path):
            a = anc[y]
            if semi[label[a]] < semi[label[y]]:
                label[y] = label[a]
            anc[y] = anc[a]
        return label[v]
    for w in range(n - 1, 0, -1):
        for v in pred[w]:
            u = eval_(v)
            if semi[u] < semi[w]:
                semi[w] = semi[u]
        bucket[semi[w]].append(w)
        anc[w] = par[w]
        p = par[w]
        for v in bucket[p]:
            u = eval_(v)
            idom[v] = u if semi[u] < semi[v] else p
        bucket[p] = []
    for w in range(1, n):
        if idom[w] != semi[w]:
            idom[w] = idom[idom[w]]
    return {pre[w]: pre[idom[w]] for w in range(1, n)}


def frontiers(V, S, r, idom):
    """Cooper–Harvey–Kennedy's runner: for each join point y (≥ 2 reachable predecessor edges,
    or y == r with any), walk from each reachable predecessor up to idom(y)."""
    P = preds_of(V, S)
    R = set(idom) | {r}
    full = dict(idom); full[r] = None
    df = {v: set() for v in R}
    for y in R:
        ps = [p for p in P[y] if p in R]
        for p in ps:
            x = p
            while x != full[y]:
                df[x].add(y)
                if x == r:
                    break
                x = full[x]
    return df


def frontiers_brute(V, S, r):
    """Cytron et al. (1991): DF(x) = {y : x dominates a reachable predecessor of y and x does not
    strictly dominate y}."""
    dom, _ = dominators_brute(V, S, r)
    P = preds_of(V, S)
    R = set(dom)
    df = {x: set() for x in R}
    for y in R:
        for p in P[y]:
            if p not in R:
                continue
            for x in dom[p]:
                if not (x in dom[y] and x != y):
                    df[x].add(y)
    return df


def children(idom, order):
    pos = {v: i for i, v in enumerate(order)}
    ch = {}
    for v, d in idom.items():
        ch.setdefault(d, []).append(v)
    return {d: sorted(c, key=pos.get) for d, c in ch.items()}
