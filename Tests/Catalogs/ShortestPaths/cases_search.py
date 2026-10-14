# The Dijkstra visitor events (Boost Graph Library order) of SP-192 and SP-194, from a plain
# model: the frontier is scanned for its smallest distance, no heap, so ties would break by
# first discovery; neither case has a tie. Prints cases_search.out.
INF = float("inf")


def events(n, edges, source):
    """edges: (u, v, w) in row order; returns the event list as tuples."""
    rows = [[] for _ in range(n)]
    for k, (u, v, w) in enumerate(edges):
        rows[u].append((k, v, w))
    dist, state, order = [INF] * n, [0] * n, []
    out = [("discover", source, 0)]
    dist[source], state[source] = 0, 1
    order.append(source)
    while True:
        frontier = [v for v in order if state[v] == 1]
        if not frontier:
            return out
        u = min(frontier, key=lambda v: dist[v])
        state[u] = 2
        out.append(("examine", u, dist[u]))
        for k, v, w in rows[u]:
            offer = dist[u] + w
            out.append(("examineEdge", (u, v), offer))
            if state[v] == 2:
                continue
            if state[v] == 0:
                dist[v], state[v] = offer, 1
                order.append(v)
                out += [("edgeRelaxed", (u, v), offer), ("discover", v, offer)]
            elif offer < dist[v]:
                dist[v] = offer
                out.append(("edgeRelaxed", (u, v), offer))
            else:
                out.append(("edgeNotRelaxed", (u, v), dist[v]))
        out.append(("finish", u, dist[u]))


sp192 = [(0, 1, 4), (0, 2, 1), (0, 3, 9), (1, 2, 0), (1, 3, 5), (2, 1, 2), (2, 3, 4), (3, 3, 5)]
sp194 = [(0, 0, 0), (0, 1, 5), (0, 1, 2), (0, 1, 2)]
for name, n, edges in [("SP-192", 5, sp192), ("SP-194", 2, sp194)]:
    result = events(n, edges, 0)
    print(f"--- {name}: {len(result)} events")
    for e in result:
        print(*e)
