"""Values for tests that are not catalog cells, computed with ref.py's model and checks."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref

F1 = "U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8"
F1b = "U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5"
NX = "D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6"
S = "U: [] a-b, b-c, b-d, d-e"
rows = []
for v in range(9):
    rows.append((F1, f"RootedTree(root: 0) > HeavyLightDecomposition : head({v})"))
    rows.append((F1, f"RootedTree(root: 0) > HeavyLightDecomposition : heavyChild({v})"))
    rows.append((F1, f"RootedTree(root: 0) > HeavyLightDecomposition : position({v})"))
    rows.append((F1, f"RootedTree(root: 0) > HeavyLightDecomposition : subtree({v})"))
for v in range(9):
    rows.append((F1, f"RootedTree(root: 4) > HeavyLightDecomposition : head({v})"))
rows += [
    (NX, "Arborescence > HeavyLightDecomposition : preorder"),
    (S, "RootedTree(root: c) > HeavyLightDecomposition : preorder"),
    (S, "RootedTree(root: c) > HeavyLightDecomposition : segments(e, a)"),
    (S, "RootedTree(root: c) > HeavyLightDecomposition : segments(a, e, includingCommonAncestor: false)"),
    (F1, "RootedTree(root: 4) > HeavyLightDecomposition : segments(8, 3)"),
    (F1, "RootedTree(root: 4) > HeavyLightDecomposition : segments(3, 8, includingCommonAncestor: false)"),
    (F1, "RootedTree(root: 0) > HeavyLightDecomposition : segments(6, 3, includingCommonAncestor: false)"),
    (F1, "RootedTree(root: 0) > HeavyLightDecomposition : segments(8, 7, includingCommonAncestor: false)"),
    (F1, "RootedTree(root: 0) > HeavyLightDecomposition : segments(4, 3)"),
    (F1, "RootedTree(root: 0) > HeavyLightDecomposition : segments(3, 4)"),
    (F1, "RootedTree(root: 0) > HeavyLightDecomposition : segments(6, 6, includingCommonAncestor: false)"),
    ("U: [] kary(63,2)", "RootedTree(root: 0) > HeavyLightDecomposition : segments(31, 62)"),
    ("U: [] kary(63,2)", "RootedTree(root: 0) > HeavyLightDecomposition : segments(62, 31, includingCommonAncestor: false)"),
    # Double versions of Int-weighted cases
    ("U: [] P(0..4)", "Tree : center(weight: [1.0, 1.0, 1.0, 10.0])"),
    ("U: [] 0-1", "Tree : center(weight: [5.0])"),
    ("U: [] P(0..2)", "Tree : center(weight: [0.0, 0.0])"),
    ("U: [] P(0..3)", "Tree : center(weight: [0.0, 1.0, 0.0])"),
    ("U: [] P(0..3)", "Tree : center(weight: [1.0, 0.0, 1.0])"),
    ("U: [] S(0;1..4)", "Tree : center(weight: [3.0, 1.0, 3.0, 2.0])"),
    ("U: [] S(0;1..4)", "Tree : center(weight: [3.0, 1.0, 30.0, 2.0])"),
    ("U: [] P(0..2)", "Tree : center(weight: [-0.0, -0.0])"),
    ("U: [] P(0..2)", "Tree : diameterPath(weight: [-0.0, -0.0])"),
    ("U: [] P(0..4)", "Tree : diameterPath(weight: [1.0, 1.0, 1.0, 10.0])"),
    ("U: [] S(0;1..4)", "Tree : diameterPath(weight: [3.0, 1.0, 3.0, 2.0])"),
    ("U: [] P(0..2)", "Tree : diameterPath(weight: [0.0, 0.0])"),
    ("U: [] P(0..3)", "Tree : diameterPath(weight: [0.0, 1.0, 0.0])"),
    (F1, "Tree : diameterPath(weight: [5.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0])"),
    ("U: [] P(0..3)", "Tree : diameterPath(weight: [0.5, 0.25, 0.75])"),
    ("U: [] P(0..3)", "Tree : center(weight: [1, 0, 1])"),
    ("U: [] P(0..3)", "Tree : diameter(weight: [0, 1, 0])"),
    ("U: [] P(0..2)", "Tree : diameter(weight: [0, 0])"),
    ("U: [] S(0;1..4)", "Tree : diameter(weight: [3, 1, 30, 2])"),
    ("U: [] S(0;1..4)", "Tree : diameterPath(weight: [3, 1, 30, 2])"),
    (F1, "Tree : center(weight: [5, 1, 1, 1, 1, 1, 1, 1])"),
    (F1b, "Tree : center"),
    (F1b, "Tree : centroid"),
    (F1b, "Tree : centroidDecomposition"),
    ("U: [4, 2, 7, 1] 7-2, 2-4, 4-1", "Tree : diameterPath"),
    ("U: [4, 2, 7, 1] 7-2, 2-4, 4-1", "Tree : centroidDecomposition"),
    ("U: [] S(0;1..6), P(6,7,8,9,10)", "Tree : diameter"),
    ("U: [] kary(8,2)", "Tree : centroidDecomposition"),
    ("U: [] kary(63,2)", "Tree : centroid"),
    ("U: [] kary(63,2)", "Tree : center"),
    ("U: [] 3-1, 1-2, 1-0", "RootedTree(root: 3) > LowestCommonAncestors : distance(2, 0)"),
    ("U: [] 3-1, 1-2, 1-0", "RootedTree(root: 3) > HeavyLightDecomposition : preorder"),
    ("U: [] P(0..140)", "RootedTree(root: 70) > LowestCommonAncestors : lowestCommonAncestor(63, 64)"),
    ("U: [] P(0..140)", "RootedTree(root: 70) > LowestCommonAncestors : lowestCommonAncestor(6, 7)"),
    ("U: [] P(0..140)", "RootedTree(root: 70) > LowestCommonAncestors : distance(6, 134)"),
    ("U: [] S(0;1..150)", "RootedTree(root: 7) > LowestCommonAncestors : lowestCommonAncestor(150, 64)"),
    ("U: [] S(0;1..150)", "RootedTree(root: 7) > LowestCommonAncestors : distance(150, 64)"),
    ("U: [] kary(63,2)", "RootedTree(root: 0) > LowestCommonAncestors : lowestCommonAncestor(62, 61)"),
    ("U: [] kary(63,2)", "RootedTree(root: 0) > LowestCommonAncestors : lowestCommonAncestor(62, 31)"),
    ("U: [] kary(63,2)", "RootedTree(root: 0) > LowestCommonAncestors : distance(62, 31)"),
    ("U: [] kary(1000000,2)", "RootedTree(root: 0) > LowestCommonAncestors : distance(999999, 524287)"),
    ("U: [] kary(1000000,2)", "RootedTree(root: 0) > HeavyLightDecomposition : lowestCommonAncestor(999999, 524287)"),
    ("U: [] P(0..999999)", "RootedTree(root: 500000) > HeavyLightDecomposition : lowestCommonAncestor(0, 999999)"),
    ("U: [] P(0..999999)", "RootedTree(root: 0) : lowestCommonAncestor(999999, 500000)"),
    ("U: [] P(0..999999)", "Tree : diameterPath"),
    ("U: [] S(0;1..999999)", "Tree : diameter(weight: 2)"),
]
for src, op in rows:
    print(f"{src} | {op} | {ref.evaluate(src, op)}")
