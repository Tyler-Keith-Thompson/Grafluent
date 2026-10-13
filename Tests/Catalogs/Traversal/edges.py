"""Section P of the catalog: the edge-position searches, on an independent reference model.

The model follows Boost.Graph's `undirected_dfs` (`undirected_dfs.hpp`): every edge has a colour, and
an edge is reported only the first time a row reaches it, so an undirected edge is reported once
from whichever end examines it first. A directed edge is in one row only, so every directed edge
is reported. Classification at that first examination is CLRS's: an undiscovered target makes a
tree edge, a discovered unfinished one a back edge, a finished one a forward edge (discovered
later than the vertex being explored) or a cross edge. Rows are built as the test conformers in
GrafluentTestSupport build them: ReferenceDirectedMultigraph lists each vertex's out-edges in
written order; ReferencePseudograph lists each edge at its `u` end and then its `v` end, in written
order, so a self-loop is listed twice.

`python3 edges.py` prints the rows of section P; gen.py imports this file to write
EdgeSearchTranscriptTests.swift.
"""
from collections import deque


def graph(vertices, edges, undirected):
    """(vertex order, rows): rows[v] is a list of (position, far end)."""
    order = []
    for v in list(vertices) + [x for e in edges for x in e]:
        if v not in order:
            order.append(v)
    rows = {v: [] for v in order}
    for k, (a, b) in enumerate(edges):
        rows[a].append((k, b))
        if undirected:
            rows[b].append((k, a))
    return order, rows


def edge_dfs(vertices, edges, undirected, roots=None, depth_limit=None, prune=()):
    order, rows = graph(vertices, edges, undirected)
    colour, d, reached, ev, t = {}, {}, set(), [], 0
    for r in (order if roots is None else roots):
        if r in colour:
            continue
        colour[r] = 'gray'; d[r] = t; t += 1; ev.append(('D', r))
        explore = r not in prune and depth_limit != 0
        stack = [(r, iter(rows[r] if explore else []), 0)]
        while stack:
            u, it, du = stack[-1]
            for k, w in it:
                if k in reached:
                    continue
                reached.add(k)
                c = colour.get(w)
                if c is None:
                    ev.append(('T', k))
                    colour[w] = 'gray'; d[w] = t; t += 1; ev.append(('D', w))
                    explore = w not in prune and (depth_limit is None or du + 1 < depth_limit)
                    stack.append((w, iter(rows[w] if explore else []), du + 1))
                    break
                elif c == 'gray':
                    ev.append(('B', k))
                else:
                    ev.append(('F' if d[w] > d[u] else 'C', k))
            else:
                stack.pop(); colour[u] = 'black'; ev.append(('X', u))
    return ev


def edge_bfs(vertices, edges, undirected, sources, depth_limit=None, prune=()):
    order, rows = graph(vertices, edges, undirected)
    depth, reached, ev, q = {}, set(), [], deque()
    for s in sources:
        if s in depth:
            continue
        depth[s] = 0; ev.append(('D', s)); q.append(s)
    while q:
        u = q.popleft()
        if u not in prune and (depth_limit is None or depth[u] < depth_limit):
            for k, w in rows[u]:
                if k in reached:
                    continue
                reached.add(k)
                if w not in depth:
                    depth[w] = depth[u] + 1; ev.append(('T', k)); ev.append(('D', w)); q.append(w)
                else:
                    ev.append(('N', k))
        ev.append(('X', u))
    return ev


NAMES = {'D': 'discover', 'X': 'finish', 'T': 'treeEdge', 'B': 'backEdge', 'F': 'forwardEdge',
         'C': 'crossEdge', 'N': 'nonTreeEdge'}


def compact(ev):
    """`D v`, `X v` for vertices; `T#k` and so on for the edge at position k."""
    return ' '.join(f'{c}{x}' if c in 'DX' else f'{c}#{x}' for c, x in ev)


def described(ev):
    """The events' `description`s, joined by spaces, as a test compares them."""
    return ' '.join(f'{NAMES[c]}({x})' for c, x in ev)


# (ID, title, undirected, listed vertices, edges, search, arguments). A search is 'dfs' or 'bfs';
# arguments are `from:` (a vertex or a list; omitted for a whole-graph depth-first search),
# `depthLimit:` and `prune` (the vertices `prune()` is called on right after their discovery).
ROWS = [
    ('TR-200', 'a repeated tree edge is a forward edge at its own position', False, [],
     [(0, 1), (0, 1), (1, 0)], 'dfs', {}),
    ('TR-200', 'a repeated edge is a non-tree edge at its own position', False, [],
     [(0, 1), (0, 1), (1, 0)], 'bfs', {'from': 0}),
    ('TR-201', 'each copy of a directed self-loop is a back edge', False, [0, 1],
     [(0, 0), (0, 0)], 'dfs', {}),
    ('TR-201', 'each copy of a directed self-loop is a non-tree edge', False, [0, 1],
     [(0, 0), (0, 0)], 'bfs', {'from': 0}),
    ('TR-202', 'a tripled cross edge, each copy at its position', False, [],
     [(0, 1), (1, 0), (2, 1), (2, 1), (2, 1), (1, 1)], 'dfs', {}),
    ('TR-203', 'a directed depth limit', False, [],
     [(0, 1), (1, 2), (0, 2), (2, 0), (1, 1)], 'dfs', {'from': 0, 'depthLimit': 1}),
    ('TR-203', 'a directed breadth-first depth limit', False, [],
     [(0, 1), (1, 2), (0, 2), (2, 0), (1, 1)], 'bfs', {'from': 0, 'depthLimit': 1}),
    ('TR-204', 'the tree edge is reported once; a parallel edge to the parent is a back edge', True, [],
     [(0, 1), (0, 1)], 'dfs', {'from': 0}),
    ('TR-204', 'the tree edge is reported once; a parallel edge to the parent is a non-tree edge', True, [],
     [(0, 1), (0, 1)], 'bfs', {'from': 0}),
    ('TR-205', 'an undirected self-loop is one back edge', True, [],
     [(0, 0), (0, 1), (0, 0)], 'dfs', {'from': 0}),
    ('TR-205', 'an undirected self-loop is one non-tree edge', True, [],
     [(0, 0), (0, 1), (0, 0)], 'bfs', {'from': 0}),
    ('TR-206', 'a triangle with a doubled side and a loop: tree and back edges only', True, [],
     [(0, 1), (1, 2), (2, 0), (1, 2), (2, 2)], 'dfs', {'from': 0}),
    ('TR-206', 'a triangle with a doubled side and a loop, breadth-first', True, [],
     [(0, 1), (1, 2), (2, 0), (1, 2), (2, 2)], 'bfs', {'from': 0}),
    ('TR-207', 'each edge once, reported from the end that reaches it first', True, [],
     [(0, 1), (1, 2), (1, 3), (2, 4), (3, 0), (0, 4)], 'dfs', {'from': 0}),
    ('TR-207', 'each edge once, from the end explored first', True, [],
     [(0, 1), (1, 2), (1, 3), (2, 4), (3, 0), (0, 4)], 'bfs', {'from': 0}),
    ('TR-208', 'the whole of a disconnected undirected graph', True, [5],
     [(0, 1), (2, 3), (3, 4), (4, 2), (2, 3)], 'dfs', {}),
    ('TR-209', 'an undirected depth limit leaves forward and cross edges', True, [],
     [(0, 1), (1, 2), (0, 3), (3, 2), (0, 2)], 'dfs', {'from': 0, 'depthLimit': 2}),
    ('TR-209', 'an undirected breadth-first depth limit', True, [],
     [(0, 1), (1, 2), (0, 3), (3, 2), (0, 2)], 'bfs', {'from': 0, 'depthLimit': 1}),
    ('TR-210', 'an edge to a pruned vertex is reported from its other end', True, [],
     [(0, 1), (1, 2), (2, 0), (1, 1)], 'dfs', {'from': 0, 'prune': [1]}),
    ('TR-210', 'an edge to a pruned vertex is reported from its other end, breadth-first', True, [],
     [(0, 1), (1, 2), (2, 0), (1, 1)], 'bfs', {'from': 0, 'prune': [1]}),
    ('TR-211', 'several roots; a reached root is skipped', True, [],
     [(0, 1), (2, 3), (1, 0)], 'dfs', {'from': [2, 1, 3, 0]}),
    ('TR-211', 'several sources, all discovered first', True, [],
     [(0, 1), (1, 2), (2, 0), (2, 3)], 'bfs', {'from': [0, 2]}),
]


def transcript(row):
    _, _, undirected, vertices, edges, search, args = row
    source = args.get('from')
    sources = source if isinstance(source, list) else None if source is None else [source]
    prune = args.get('prune', ())
    limit = args.get('depthLimit')
    if search == 'dfs':
        return edge_dfs(vertices, edges, undirected, roots=sources, depth_limit=limit, prune=prune)
    return edge_bfs(vertices, edges, undirected, sources, depth_limit=limit, prune=prune)


if __name__ == '__main__':
    for row in ROWS:
        ident, title, undirected, vertices, edges, search, args = row
        kind = 'undirected' if undirected else 'directed'
        listed = f' (vertices {vertices} first)' if vertices else ''
        print(f'{ident} {kind} {search} {args} on {edges}{listed} → `{compact(transcript(row))}`')
