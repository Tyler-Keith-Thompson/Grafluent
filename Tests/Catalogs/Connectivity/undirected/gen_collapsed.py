"""Prints the collapsed-row literals of UndirectedRepresentationTests.swift (CN-341)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref
from gen_tests import has_repeats, lit
rows=[]
for cid, spec, _ in ref.catalog():
    n=int(cid[3:])
    if spec is None or n>339 or spec.startswith("realworld"): continue
    vs, es = ref.parse_graph(spec)
    if not has_repeats(es) or len(es)>40 or any(isinstance(v,str) for v in vs): continue
    seen=set(); col=[]
    for u,v in es:
        k=frozenset((u,v))
        if k not in seen: seen.add(k); col.append((u,v))
    vs2, es2 = ref.make_graph(vs, col)
    assert vs2==vs
    r=ref.compute(vs2, es2)
    print(f'            ("{cid}", {lit(vs, False)}, [{", ".join(f"({a}, {b})" for a,b in es)}], {lit(r["br"],False)}, {lit(r["ap"],False)}, {lit(r["bcc"],False)}, {lit(r["becc"],False)}, {str(r["bic"]).lower()}, {str(r["bec"]).lower()}),')
