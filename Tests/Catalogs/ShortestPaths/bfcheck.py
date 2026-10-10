import io, contextlib, os, re
from ref import *
import ref
# Re-run the BF cases, report witness rotated to the smallest vertex index, and parent uniqueness.
orig = ref.bellman_ford
out = []
def show(name, vertices, edges, sources, order="written"):
    g = G(vertices, edges, order); r = orig(g, sources)
    if r[0] == "cycle":
        c = r[1]; i = c.index(min(c)); c = c[i:] + c[:i]
        out.append(f"{name}: cycle {lab(g, c)}")
    else:
        dist = r[1]; amb = []
        for v in range(g.n):
            if dist[v] is None or r[2][v] is None: continue
            cands = [(u, k) for k, (u, b, w) in enumerate(g.edges) if b == v and dist[u] is not None and dist[u] + w == dist[v]]
            if len(cands) > 1: amb.append((g.label(v), [(g.label(u), k) for u, k in cands]))
        out.append(f"{name}: tree; ambiguous parents: {amb}")
import cases_bf
cases_bf.show_bf = show
src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cases_bf.py")).read().split('print("\\n================ BELLMAN-FORD")')[1]
with contextlib.redirect_stdout(io.StringIO()):
    from cases import und, XG
exec(src, {"show_bf": show, "und": und, "XG": XG, "G": G})
print("\n".join(out))
