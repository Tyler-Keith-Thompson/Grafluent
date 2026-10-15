# The Hopcroft–Karp events of MA-1100, from a plain model of api.md's Hopcroft–Karp: rows in
# position order, left vertices in `left` order; each phase layers the left vertices by a
# breadth-first search from the free ones, then depth-first searches from each free left vertex
# descend into a mate one layer deeper and stop at the first free right vertex at the free layer.
# Prints cases_events.out. Run: python3 Tests/Catalogs/MatchingModule/cases_events.py
import os

INF = float("inf")


def events(n, edges, left):
    rows = [[] for _ in range(n)]
    for k, (u, v) in enumerate(edges):
        rows[u].append((v, k))
        rows[v].append((u, k))
    mate_edge = [None] * n  # left vertex -> matched edge
    pair = [None] * n       # right vertex -> left mate
    out = []
    while True:
        layer = {v: (0 if mate_edge[v] is None else INF) for v in left}
        queue = [v for v in left if mate_edge[v] is None]
        free, head = INF, 0
        while head < len(queue):
            v = queue[head]
            head += 1
            if layer[v] >= free:
                continue
            for w, _ in rows[v]:
                p = pair[w]
                if p is None:
                    if free == INF:
                        free = layer[v] + 1
                elif layer[p] == INF:
                    layer[p] = layer[v] + 1
                    queue.append(p)
        if free == INF:
            return out
        out.append(("phase", 2 * free - 1))
        for root in left:
            if mate_edge[root] is not None:
                continue

            def dfs(v):
                for w, k in rows[v]:
                    p = pair[w]
                    if p is None:
                        if free == layer[v] + 1:
                            return [(v, w, k)]
                    elif layer[p] == layer[v] + 1:
                        rest = dfs(p)
                        if rest is not None:
                            return [(v, w, k)] + rest
                layer[v] = INF
                return None

            path = dfs(root)
            if path is None:
                continue
            edges_out = []
            for i, (v, w, k) in enumerate(path):
                if i > 0:
                    edges_out.append(mate_edge[v])
                edges_out.append(k)
            out.append(("augmentingPath", edges_out))
            for v, w, k in path:
                pair[w] = v
                mate_edge[v] = k


# MA-1100: left 0, 1, 2, right 3, 4, 5. The first phase matches 0–3 and 2–4 (1 finds 3 taken);
# the second finds 1–3–0–4–2–5, through both matched edges.
MA1100 = [(0, 3), (0, 4), (1, 3), (2, 4), (2, 5)]
ev = events(6, MA1100, [0, 1, 2])
lines = [f"--- MA-1100: {len(ev)} events"] + [" ".join(str(x) for x in e) for e in ev]
text = "\n".join(lines) + "\n"
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cases_events.out"), "w") as f:
    f.write(text)
print(text, end="")
