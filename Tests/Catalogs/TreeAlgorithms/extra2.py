import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref
M = 10**6
t = ref.build("U: [] P(0..999999)", "Tree")
vs, es, d = t.diameter_path([1] * (M - 1))
print(vs == list(range(M)), es == list(range(M - 1)), d)
F1 = "U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8"
print(ref.evaluate(F1, "RootedTree(root: 4) : lowestCommonAncestor(3, 7)"))
# kary(10^6, 2) eulerTour / HLD extras
print(ref.evaluate("U: [] kary(1000000,2)", "RootedTree(root: 0) > HeavyLightDecomposition : segments(999999, 524287).count", check=False))
print(ref.evaluate("U: [] S(0;1..999999)", "RootedTree(root: 0) > HeavyLightDecomposition : segments(999999, 1)", check=False))
print(ref.evaluate("U: [] S(0;1..999999)", "RootedTree(root: 0) > HeavyLightDecomposition : heavyChild(0)", check=False))
print(ref.evaluate("U: [] S(0;1..999999)", "RootedTree(root: 0) > LowestCommonAncestors : lowestCommonAncestor(999999, 1)", check=False))
print(ref.evaluate("U: [] S(0;1..999999)", "RootedTree(root: 999999) : eulerTour.length", check=False))
print(ref.evaluate("U: [] P(0..999999)", "RootedTree(root: 500000) > HeavyLightDecomposition : heavyChild(500000)", check=False))
print(ref.evaluate("U: [] P(0..999999)", "RootedTree(root: 500000) > HeavyLightDecomposition : head(999999)", check=False))
