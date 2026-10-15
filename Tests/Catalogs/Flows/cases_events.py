# The Edmonds–Karp events of FL-900 and FL-901, from a plain model of the documented procedure:
# the residual network's rows list, for each edge in position order, its forward arc at the tail
# and its reverse arc at the head (self-loops get none); breadth-first search over arcs with
# residual, in row order, stops when the sink is discovered; the path is sent from the source end.
# Prints cases_events.out. Run: python3 Tests/Catalogs/Flows/cases_events.py
import os


def events(n, edges, s, t):
    """edges: (u, v, capacity) in position order; returns the event list as tuples."""
    rows = [[] for _ in range(n)]
    arcs = []  # (head, edge, forward)
    residual = []
    mate = []
    for k, (u, v, c) in enumerate(edges):
        if u == v:
            continue
        a, b = len(arcs), len(arcs) + 1
        arcs += [(v, k, True), (u, k, False)]
        residual += [c, 0]
        mate += [b, a]
        rows[u].append(a)
        rows[v].append(b)
    out = []
    while True:
        parent = {s: None}
        queue, found = [s], False
        while queue and not found:
            x = queue.pop(0)
            for a in rows[x]:
                w = arcs[a][0]
                if w not in parent and residual[a] > 0:
                    parent[w] = a
                    if w == t:
                        found = True
                        break
                    queue.append(w)
        if not found:
            return out
        path, y = [], t
        while y != s:
            a = parent[y]
            path.append(a)
            y = arcs[mate[a]][0]
        path.reverse()
        delta = min(residual[a] for a in path)
        out.append(("augmentingPath", [arcs[a][1] for a in path], delta))
        for a in path:
            residual[a] -= delta
            residual[mate[a]] += delta
            out.append(("push" if arcs[a][2] else "cancel", arcs[a][1], delta))


# FL-900: CLRS-style network (Figure 26.1's), 0 = s, 5 = t.
FL900 = [(0, 1, 16), (0, 2, 13), (2, 1, 4), (1, 3, 12), (3, 2, 9), (2, 4, 14), (4, 3, 7), (3, 5, 20), (4, 5, 4)]
# FL-901: the second path cancels the middle edge 2 (1 → 2) taken by the first; a self-loop at 1
# and a parallel copy 0 → 3 that the third search finds no use for.
FL901 = [(0, 1, 1), (1, 1, 5), (1, 2, 1), (2, 5, 1), (0, 3, 1), (3, 2, 1), (1, 4, 1), (4, 5, 1), (0, 3, 4)]
lines = []
for name, n, edges in [("FL-900", 6, FL900), ("FL-901", 6, FL901)]:
    ev = events(n, edges, 0, 5)
    lines.append(f"--- {name}: {len(ev)} events, value {sum(e[2] for e in ev if e[0] == 'augmentingPath')}")
    lines += [" ".join(str(x) for x in e) for e in ev]
text = "\n".join(lines) + "\n"
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cases_events.out"), "w") as f:
    f.write(text)
print(text, end="")
