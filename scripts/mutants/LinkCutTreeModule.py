# Planted bugs for LinkCutTreeModule; run with `just mutate LinkCutTreeModule`. See
# scripts/mutate.py.
#
# Known equivalent mutants (they survive by design):
#   lczigzig    rotating x twice in a zig-zig step instead of its parent first: still rotations
#               that bring x to the root, so every answer is the same; only the amortized bound
#               is lost (time only).
#   lccutpull   no pull after cutting: `vertex` is then the root of its splay tree, and nothing
#   lcsetcost   no pull after setting a cost: reads its aggregate before a rotation or an access
#               pulls it again (an access pulls every node it climbs through, a rotation both
#               nodes it moves), so the stale aggregate is never read.
#   lccount     no check of a negative count: building `0 ..< count` traps anyway; only the
#               message differs.

TESTS = ["LinkCutTreeTests"]

L = "LinkCutTree.swift"

MUTANTS = [
    Mutant("lcsplayroot", L, "return p < 0 || (nodes[p].left != x && nodes[p].right != x)", "return p < 0 || nodes[p].left != x", mode="stmt"),
    Mutant("lcapplymin", L, "nodes[x].minimum = nodes[x].minimum + addition - subtraction", "nodes[x].minimum = nodes[x].minimum", mode="stmt"),
    Mutant("lcapplysub", L, "nodes[x].pendingSubtraction += subtraction", "nodes[x].pendingSubtraction += .zero", mode="stmt"),
    Mutant("lcapplyadd", L, "nodes[x].pendingAddition += addition", "nodes[x].pendingAddition = addition", mode="stmt"),
    Mutant("lcpushright", L, "if nodes[x].right >= 0 { _apply(nodes, nodes[x].right, addition, subtraction) }", "", mode="stmt"),
    Mutant("lcpushclear", L, "nodes[x].pendingAddition = .zero", "()", mode="stmt"),
    Mutant("lcpushrev", L, "if l >= 0 { nodes[l].reversed.toggle() }", "", mode="stmt"),
    Mutant("lcpullleft", L, "l >= 0 && nodes[l].minimum < minimum", "l >= 0 && nodes[l].minimum > minimum"),
    Mutant("lcpullright", L, "r >= 0 && nodes[r].minimum < minimum", "false"),
    Mutant("lcpullarg", L, "argmin = nodes[l].argmin", "argmin = l", mode="stmt"),
    Mutant("lcrotatez", L, "if nodes[z].left == y { nodes[z].left = x } else { nodes[z].right = x }", "nodes[z].left = x", mode="stmt"),
    Mutant("lcrotatepull", L, "        _pull(nodes, y)\n        _pull(nodes, x)\n", "        _pull(nodes, x)\n", mode="stmt"),
    Mutant("lcaccessright", L, "nodes[y].right = below", "nodes[y].right = nodes[y].right", mode="stmt"),
    Mutant("lcaccesssplay", L, "_splay(nodes, stack, x)", "", mode="stmt", nth=1),
    Mutant("lcrootsplay", L, "        _splay(nodes, stack, r)\n        return r", "        return r", mode="stmt"),
    Mutant("lcparentright", L, "            while nodes[x].right >= 0 {\n                x = nodes[x].right\n                Self._push(nodes, x)\n            }", "", mode="stmt"),
    Mutant("lclinkcheck", L, "Self._findRoot(nodes, stack, parent) != child", "true"),
    Mutant("lclinkroot", L, "nodes[child].left < 0", "true"),
    Mutant("lccutcheck", L, "precondition(above >= 0, \"cut(_:) needs a vertex that has a parent\")", "", mode="stmt"),
    Mutant("lcmakeroot", L, "nodes[vertex].reversed.toggle()", "nodes[vertex].reversed = false", mode="stmt"),
    Mutant("lccostsplay", L, "            Self._splay(nodes, stack, vertex)\n            return nodes[vertex].cost", "            return nodes[vertex].cost", mode="stmt"),
    Mutant("lcsubtract", L, "Self._apply(nodes, vertex, .zero, delta)", "Self._apply(nodes, vertex, delta, .zero)"),
    Mutant("lcrange", L, "UInt(bitPattern: vertex) < UInt(bitPattern: _nodes.count)", "vertex < _nodes.count"),
]
