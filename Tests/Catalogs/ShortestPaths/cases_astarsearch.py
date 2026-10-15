# The A* visitor events (Boost Graph Library order, with reopening) of SP-201, from a plain model:
# the open set is scanned for its smallest distance plus estimate, no heap, so ties would break by
# first opening; the case has no tie. The target's own estimate (7) is taken as zero. Prints
# cases_astarsearch.out.
# Run: python3 Tests/Catalogs/ShortestPaths/cases_astarsearch.py
import os

INF = float("inf")


def events(n, edges, source, target, h):
    """edges: (u, v, w) in row order; h: the estimates (h[target] is taken as 0)."""
    rows = [[] for _ in range(n)]
    for k, (u, v, w) in enumerate(edges):
        rows[u].append((k, v, w))
    est = [0 if v == target else h[v] for v in range(n)]
    dist, state, order = [INF] * n, [0] * n, []
    dist[source], state[source] = 0, 1
    order.append(source)
    out = [("discover", source, 0, est[source])]
    while True:
        frontier = [v for v in order if state[v] == 1]
        if not frontier:
            return out
        u = min(frontier, key=lambda v: dist[v] + est[v])
        state[u] = 2
        out.append(("examine", u, dist[u], est[u]))
        if u == target:
            return out
        for k, v, w in rows[u]:
            offer = dist[u] + w
            out.append(("examineEdge", k, offer))
            if state[v] == 0 or offer < dist[v]:
                was = state[v]
                dist[v], state[v] = offer, 1
                if v not in order:
                    order.append(v)
                out.append(("edgeRelaxed", k, offer))
                if was == 0:
                    out.append(("discover", v, offer, est[v]))
                elif was == 2:
                    out.append(("reopen", v, offer, est[v]))
            else:
                out.append(("edgeNotRelaxed", k, dist[v]))
        out.append(("finish", u, dist[u]))


# SP-201: an inconsistent but admissible estimate at 1 (5 > w(1→2) + h(2)) reopens 2 and 3; a loop
# at 1 and a heavier parallel copy 0→2. Edges in row order, so every representation's positions
# are these.
sp201 = [(0, 1, 1), (0, 2, 4), (0, 2, 6), (1, 2, 1), (1, 1, 2), (2, 3, 1), (3, 4, 5)]
lines = []
for name, n, edges, s, t, h in [("SP-201", 5, sp201, 0, 4, [0, 5, 0, 0, 7])]:
    ev = events(n, edges, s, t, h)
    lines.append(f"--- {name}: {len(ev)} events")
    lines += [" ".join(str(x) for x in e) for e in ev]
text = "\n".join(lines) + "\n"
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cases_astarsearch.out"), "w") as f:
    f.write(text)
print(text, end="")
