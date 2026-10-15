# The event sequences of ST-250 and ST-251 (Kruskal) and ST-260 and ST-261 (Prim), from plain
# models: Kruskal sorts (weight, position) and keeps union–find roots by size, the larger set's
# root staying and, on a tie, the smaller one; Prim scans its frontier for the smallest key, so
# ties break by the order vertices entered it (neither Prim case has a tie in its frontier).
# Prints cases_events.out. Run: python3 Tests/Catalogs/SpanningTrees/cases_events.py
import os

INF = float("inf")


def kruskal_events(n, edges):
    """edges: (u, v, w) in position order; returns the event list as tuples."""
    parent, size = list(range(n)), [1] * n

    def find(x):
        while parent[x] != x:
            x = parent[x]
        return x

    out, taken = [], 0
    order = sorted((w, k) for k, (u, v, w) in enumerate(edges) if u != v)
    for w, k in order:
        if taken == n - 1:
            break
        u, v, _ = edges[k]
        out.append(("examineEdge", k, w))
        a, b = find(u), find(v)
        if a == b:
            out.append(("nonTreeEdge", k, a))
            continue
        root, child = (a, b) if size[a] > size[b] or (size[a] == size[b] and a < b) else (b, a)
        parent[child], size[root] = root, size[a] + size[b]
        taken += 1
        out.append(("treeEdge", k, child, root))
    return out


def prim_events(n, edges, roots):
    """Prim from each root in `roots` order that is not yet spanned; returns the events."""
    inc = [[] for _ in range(n)]
    for k, (u, v, w) in enumerate(edges):
        inc[u].append((k, v, w))
        if u != v:
            inc[v].append((k, u, w))
    spanned, key, frontier, out = [False] * n, [INF] * n, [], []
    for r in roots:
        if spanned[r]:
            continue
        out.append(("startVertex", r))
        key[r] = 0
        frontier.append(r)
        while frontier:
            u = min(frontier, key=lambda x: key[x])
            frontier.remove(u)
            spanned[u] = True
            out.append(("examine", u, key[u]))
            for k, v, w in inc[u]:
                if spanned[v]:
                    continue
                out.append(("examineEdge", k, w))
                if w < key[v]:
                    if key[v] == INF:
                        frontier.append(v)
                    key[v] = w
                    out.append(("edgeRelaxed", k, w))
                else:
                    out.append(("edgeNotRelaxed", k, key[v]))
            out.append(("finish", u))
    return out


WIKI = [(0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6),
        (4, 5, 8), (4, 6, 9), (5, 6, 11)]
# ST-251 / ST-261: a self-loop, three parallel copies 0–1 (4, 2, 2), a triangle 1–2–3 and an
# isolated vertex 4; then a second component 5–6.
MULTI = [(0, 0, 1), (0, 1, 4), (1, 0, 2), (0, 1, 2), (1, 2, 3), (2, 3, 1), (3, 1, 3), (5, 6, 7)]

lines = []
for name, n, edges, kind in [("ST-250", 7, WIKI, "kruskal"), ("ST-251", 7, MULTI, "kruskal"),
                             ("ST-260", 7, WIKI, "prim"), ("ST-261", 7, MULTI, "prim")]:
    ev = kruskal_events(n, edges) if kind == "kruskal" else prim_events(n, edges, range(n))
    lines.append(f"--- {name}: {len(ev)} events")
    lines += [" ".join(str(x) for x in e) for e in ev]
text = "\n".join(lines) + "\n"
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cases_events.out"), "w") as f:
    f.write(text)
print(text, end="")
