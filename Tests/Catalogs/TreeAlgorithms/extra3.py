import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref
t = ref.build("U: [] P(0..999999)", "RootedTree(root: 0)")
vs, es = t.euler()
print(vs[999999], vs[0], vs[-1])
t = ref.build("U: [] P(0..999999)", "RootedTree(root: 0)")
heavy, order, head, hpos = t.hld()
print(head[999999])
