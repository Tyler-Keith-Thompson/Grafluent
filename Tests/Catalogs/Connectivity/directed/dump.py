"""Prints every expected value used in test-catalog-connectivity.md."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sys
from fixtures import F
import ref

def fmt(x):
    return repr(x).replace("'", '"')

def comps_line(V, S):
    c, st = ref.tarjan(V, S)
    return c, st

print('=== Strong components, ascending (AM/CSR), within = vertices order; also stack order')
for name, f in F.items():
    if name in ('gap4', 'graph500Scale8', 'ligraRMat'):
        continue
    V, S = ref.ascending(f)
    c, st = ref.tarjan(V, S)
    w = ref.weak(V, S)
    rows = ref.condensation(V, S, c)
    att = ref.attracting(V, S, c)
    print(f'{name}: n={len(V)} scc={fmt(c)}')
    if st != c:
        print(f'   stack order: {fmt(st)}')
    print(f'   label={fmt([ref.labels(c)[v] for v in V])} cond={fmt(rows)} attracting={fmt(att)}')
    print(f'   weak={fmt(w)} strong?={len(c)==1} weak?={len(w)==1}')
    Vw, Sw = ref.written(f)
    cw, stw = ref.tarjan(Vw, Sw)
    if cw != c or Vw != V:
        print(f'   MULTIGRAPH vertices={fmt(Vw)} scc={fmt(cw)} weak={fmt(ref.weak(Vw, Sw))} cond={fmt(ref.condensation(Vw,Sw,cw))}')
