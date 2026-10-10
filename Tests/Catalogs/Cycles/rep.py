"""Values for the hand-written tests of rep_tail.swift: graphs with custom row orders."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref
def custom(listed, edges, rows, directed=False):
    g = ref.G(listed, edges, directed)
    g.rows = []
    for i, r in enumerate(rows):
        row = []
        for e in r:
            a, b = g.ends[e]
            w = b if a == i else a
            if directed: w = b
            row.append((w, e))
        g.rows.append(row)
    g.offset = []
    for i in range(g.n):
        d = {}
        for k, (_, e) in enumerate(g.rows[i]):
            d.setdefault(e, k)
        g.offset.append(d)
    return g
def show(name, g):
    print(name)
    print("  simple:", ref.fmt_list(g, ref.brute_cycles(g)))
    assert [ref.canonical(g, list(v), list(e)) for v, e in ref.proposed_cycles(g)] == ref.brute_cycles(g)
    if not g.directed:
        c = ref.find_cycle(g); print("  find:", c and ref.fmt_cycle(g, c))
        print("  basis:", ref.fmt_list(g, ref.cycle_basis(g)))
    print("  girth:", ref.girth_edges(g), ref.girth_bfs(g))
def outin(n, arcs):
    rows = []
    for v in range(n):
        out = [k for k, (a, b) in enumerate(arcs) if a == v]
        inn = [k for k, (a, b) in enumerate(arcs) if b == v]
        rows.append(out + inn)
    return rows
# matrix.undirected of K4 upper cells (positions = row-major cell order)
k4 = [(0,1),(0,2),(0,3),(1,2),(1,3),(2,3)]
show("K4 upper cells .undirected", custom(range(4), k4, outin(4, k4)))
# matrix with sorted in-lists: for a general cell set, in-lists ascending by source == position order since row-major
d708 = [(0,1),(1,0),(1,2),(2,0)]
show("CY-708 view", custom([0,1,2], d708, outin(3, d708)))
d423 = [(0,1),(1,0),(1,0)]
show("CY-423 view", custom([0,1], d423, outin(2, d423)))
# CY-119 0-1 1-2 2-0 0-1 2-2 as digraph.undirected (arcs as written)
d119 = [(0,1),(1,2),(2,0),(0,1),(2,2)]
show("CY-119 as arcs .undirected", custom([0,1,2], d119, outin(3, d119)))
# matrix of a symmetric triangle with loop: cells row-major
sym = sorted([(0,1),(1,0),(1,2),(2,1),(2,0),(0,2),(1,1)])
print(sym)
show("sym triangle+loop matrix.undirected", custom(range(3), sym, outin(3, sym)))
