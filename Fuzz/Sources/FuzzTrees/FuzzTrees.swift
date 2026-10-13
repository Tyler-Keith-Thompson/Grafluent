// Trees against brute force, on edge lists of at most 9 vertices with repeated edges and
// self-loops: Tree, Forest and Arborescence exist exactly when the definitions hold (and agree with
// isTree and isArborescence); for every root of a tree, parent, depth, children, preorder,
// postorder, descendants, ancestors and isAncestor agree with a breadth-first search, and every
// path with the unique one; the Prüfer sequence decodes back to the same tree and does not depend on
// the order 0..<n is listed in; the parent function
// rebuilds it; a forest's trees are its components by least vertex; the Graph laws hold. Every
// `checked:` spelling returns its plain spelling's value at a vertex (also over `String` vertices,
// which take the linear search or the hash table) and throws `VertexNotFound` off the tree, or
// `EdgeNotFound` off an arborescence's positions.

import AdjacencyListModule
import FuzzSupport
import GraphProtocols
import Trees
import Walks

@main
enum FuzzTrees {
    static func main() { runFuzzer(fuzz) }

    /// Whether `body` throws `VertexNotFound`.
    static func missing<R>(_ body: () throws(VertexNotFound) -> R) -> Bool {
        do { _ = try body(); return false } catch { return true }
    }

    /// Whether `body` throws `EdgeNotFound`.
    static func noEdge<R>(_ body: () throws(EdgeNotFound) -> R) -> Bool {
        do { _ = try body(); return false } catch { return true }
    }

    /// Vertices that are not in a tree on 0..<n.
    static func outside(_ n: Int) -> [Int] { [-1, n, n + 7, Int.min, Int.max] }

    /// Every `checked:` spelling of a rooted tree and its arborescence against the plain one.
    static func checkChecked(_ tree: RootedTree<Int>, _ arborescence: Arborescence<Int>, _ n: Int) {
        for v in 0 ..< n {
            do throws(VertexNotFound) {
                let parent = try tree.parent(checked: v), parentEdge = try tree.parentEdge(checked: v)
                let children = Array(try tree.children(checked: v)), depth = try tree.depth(checked: v)
                let descendants = Array(try tree.descendants(checked: v)), ancestors = Array(try tree.ancestors(checked: v))
                let neighbors = Array(try tree.neighbors(checked: v)), incident = try tree.incidentEdges(checked: v)
                let degree = try tree.degree(checked: v), index = try tree.vertexIndex(checked: v)
                check(parent == tree.parent(of: v) && parentEdge == tree.parentEdge(of: v), "parent(checked: \(v))")
                check(children == Array(tree.children(of: v)) && depth == tree.depth(of: v), "children(checked: \(v))")
                check(descendants == Array(tree.descendants(of: v)) && ancestors == Array(tree.ancestors(of: v)), "descendants(checked: \(v))")
                check(neighbors == Array(tree.neighbors(of: v)) && incident == tree.incidentEdges(of: v), "neighbors(checked: \(v))")
                check(degree == tree.degree(of: v) && index == v, "degree(checked: \(v))")
                let aParent = try arborescence.parent(checked: v), aParentEdge = try arborescence.parentEdge(checked: v)
                let aChildren = Array(try arborescence.children(checked: v)), aDepth = try arborescence.depth(checked: v)
                let aDescendants = Array(try arborescence.descendants(checked: v)), aAncestors = Array(try arborescence.ancestors(checked: v))
                let successors = Array(try arborescence.successors(checked: v)), predecessors = Array(try arborescence.predecessors(checked: v))
                let outEdges = Array(try arborescence.outEdges(checked: v)), inEdges = Array(try arborescence.inEdges(checked: v))
                let outDegree = try arborescence.outDegree(checked: v), inDegree = try arborescence.inDegree(checked: v)
                let aDegree = try arborescence.degree(checked: v), aIndex = try arborescence.vertexIndex(checked: v)
                check(aParent == arborescence.parent(of: v) && aParentEdge == arborescence.parentEdge(of: v), "arborescence parent(checked: \(v))")
                check(aChildren == Array(arborescence.children(of: v)) && aDepth == arborescence.depth(of: v), "arborescence children(checked: \(v))")
                check(aDescendants == Array(arborescence.descendants(of: v)) && aAncestors == Array(arborescence.ancestors(of: v)), "arborescence descendants(checked: \(v))")
                check(successors == Array(arborescence.successors(of: v)) && predecessors == Array(arborescence.predecessors(of: v)), "successors(checked: \(v))")
                check(outEdges == Array(arborescence.outEdges(of: v)) && inEdges == Array(arborescence.inEdges(of: v)), "outEdges(checked: \(v))")
                check(outDegree == arborescence.outDegree(of: v) && inDegree == arborescence.inDegree(of: v), "outDegree(checked: \(v))")
                check(aDegree == arborescence.degree(of: v) && aIndex == v, "arborescence degree(checked: \(v))")
                for w in 0 ..< n {
                    let above = try tree.isAncestor(checked: w, of: v), aAbove = try arborescence.isAncestor(checked: w, of: v)
                    check(above == tree.isAncestor(w, of: v) && aAbove == arborescence.isAncestor(w, of: v), "isAncestor(checked: \(w), of: \(v))")
                    let path = try tree.path(checkedFrom: w, to: v), aPath = try arborescence.path(checkedFrom: w, to: v)
                    check(path.edges == tree.path(from: w, to: v).edges, "path(checkedFrom: \(w), to: \(v))")
                    check(aPath?.edges == arborescence.path(from: w, to: v)?.edges, "arborescence path(checkedFrom: \(w), to: \(v))")
                }
            } catch {
                check(false, "a checked: spelling threw at vertex \(v)")
            }
            for x in outside(n) {
                check(missing { () throws(VertexNotFound) in try tree.isAncestor(checked: x, of: v) } && missing { () throws(VertexNotFound) in try tree.isAncestor(checked: v, of: x) }, "isAncestor(checked:) off the tree")
                check(missing { () throws(VertexNotFound) in try tree.path(checkedFrom: x, to: v) } && missing { () throws(VertexNotFound) in try arborescence.path(checkedFrom: v, to: x) }, "path(checkedFrom:to:) off the tree")
            }
        }
        for e in 0 ..< n - 1 {
            check((try? arborescence.source(checkedEdgeAt: e)) == arborescence.source(ofEdgeAt: e) && (try? arborescence.target(checkedEdgeAt: e)) == arborescence.target(ofEdgeAt: e), "source(checkedEdgeAt: \(e))")
        }
        for e in [-1, n - 1, n, Int.min, Int.max] {
            check(noEdge { () throws(EdgeNotFound) in try arborescence.source(checkedEdgeAt: e) } && noEdge { () throws(EdgeNotFound) in try arborescence.target(checkedEdgeAt: e) }, "source(checkedEdgeAt: \(e)) off the positions")
        }
        for x in outside(n) {
            check(missing { () throws(VertexNotFound) in try tree.parent(checked: x) } && missing { () throws(VertexNotFound) in try tree.parentEdge(checked: x) }, "parent(checked: \(x))")
            check(missing { () throws(VertexNotFound) in try tree.children(checked: x) } && missing { () throws(VertexNotFound) in try tree.depth(checked: x) }, "children(checked: \(x))")
            check(missing { () throws(VertexNotFound) in try tree.descendants(checked: x) } && missing { () throws(VertexNotFound) in try tree.ancestors(checked: x) }, "descendants(checked: \(x))")
            check(missing { () throws(VertexNotFound) in try tree.neighbors(checked: x) } && missing { () throws(VertexNotFound) in try tree.incidentEdges(checked: x) }, "neighbors(checked: \(x))")
            check(missing { () throws(VertexNotFound) in try tree.degree(checked: x) } && missing { () throws(VertexNotFound) in try tree.vertexIndex(checked: x) }, "degree(checked: \(x))")
            check(missing { () throws(VertexNotFound) in try arborescence.parent(checked: x) } && missing { () throws(VertexNotFound) in try arborescence.parentEdge(checked: x) }, "arborescence parent(checked: \(x))")
            check(missing { () throws(VertexNotFound) in try arborescence.children(checked: x) } && missing { () throws(VertexNotFound) in try arborescence.depth(checked: x) }, "arborescence children(checked: \(x))")
            check(missing { () throws(VertexNotFound) in try arborescence.descendants(checked: x) } && missing { () throws(VertexNotFound) in try arborescence.ancestors(checked: x) }, "arborescence descendants(checked: \(x))")
            check(missing { () throws(VertexNotFound) in try arborescence.successors(checked: x) } && missing { () throws(VertexNotFound) in try arborescence.predecessors(checked: x) }, "successors(checked: \(x))")
            check(missing { () throws(VertexNotFound) in try arborescence.outEdges(checked: x) } && missing { () throws(VertexNotFound) in try arborescence.inEdges(checked: x) }, "outEdges(checked: \(x))")
            check(missing { () throws(VertexNotFound) in try arborescence.outDegree(checked: x) } && missing { () throws(VertexNotFound) in try arborescence.inDegree(checked: x) }, "outDegree(checked: \(x))")
            check(missing { () throws(VertexNotFound) in try arborescence.degree(checked: x) } && missing { () throws(VertexNotFound) in try arborescence.vertexIndex(checked: x) }, "arborescence degree(checked: \(x))")
        }
    }

    /// Component labels of 0..<n by first vertex, and whether the edges hold a cycle.
    static func components(_ n: Int, _ edges: [(Int, Int)]) -> (labels: [Int], cyclic: Bool) {
        var parent = Array(0 ..< n)
        func find(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        var cyclic = false
        for (a, b) in edges {
            let (ra, rb) = (find(a), find(b))
            if ra == rb { cyclic = true } else { parent[ra] = rb }
        }
        var label = [Int](repeating: -1, count: n), roots: [Int: Int] = [:]
        for v in 0 ..< n {
            let r = find(v)
            if roots[r] == nil { roots[r] = roots.count }
            label[v] = roots[r]!
        }
        return (label, cyclic)
    }

    static func checkRooted(_ tree: RootedTree<Int>, _ n: Int, _ edges: [(Int, Int)], _ root: Int) {
        // Brute force: a breadth-first search from the root over the edge list in position order.
        var parent = [Int?](repeating: nil, count: n), depth = [Int](repeating: -1, count: n)
        depth[root] = 0
        var queue = [root], head = 0
        while head < queue.count {
            let v = queue[head]
            head += 1
            for (a, b) in edges where a == v || b == v {
                let w = a == v ? b : a
                if depth[w] < 0 {
                    depth[w] = depth[v] + 1
                    parent[w] = v
                    queue.append(w)
                }
            }
        }
        check(tree.root == root && tree.rootIndex == root, "root")
        check(tree.height == depth.max()!, "height \(tree.height)")
        for v in 0 ..< n {
            check(tree.parent(of: v) == parent[v] && tree.parent(ofIndex: v) == parent[v], "parent of \(v)")
            check(tree.depth(of: v) == depth[v] && tree.depth(ofIndex: v) == depth[v], "depth of \(v)")
            let expectedChildren = edges.indices.filter { k in
                let (a, b) = edges[k]
                return (a == v && parent[b] == v) || (b == v && parent[a] == v && a != b)
            }.map { edges[$0].0 == v ? edges[$0].1 : edges[$0].0 }
            check(Array(tree.children(of: v)) == expectedChildren, "children of \(v): \(Array(tree.children(of: v))), expected \(expectedChildren)")
            if let pe = tree.parentEdge(of: v) {
                let (a, b) = edges[pe]
                check(Set([a, b]) == Set([v, parent[v]!]), "parentEdge of \(v)")
            } else {
                check(v == root, "parentEdge of \(v)")
            }
            var up: [Int] = [], x = v
            while let p = parent[x] { up.append(p); x = p }
            check(Array(tree.ancestors(of: v)) == up, "ancestors of \(v)")
            for w in 0 ..< n { check(tree.isAncestor(w, of: v) == up.contains(w), "isAncestor(\(w), of: \(v))") }
        }
        // Preorder: the root, then each child's subtree in children order; postorder likewise.
        var pre: [Int] = [], post: [Int] = []
        var stack: [(Int, Int)] = [(root, 0)]
        pre.append(root)
        while let (v, k) = stack.last {
            let children = Array(tree.children(of: v))
            if k < children.count {
                stack[stack.count - 1].1 = k + 1
                pre.append(children[k])
                stack.append((children[k], 0))
            } else {
                post.append(v)
                stack.removeLast()
            }
        }
        check(Array(tree.preorder) == pre, "preorder \(Array(tree.preorder)), expected \(pre)")
        check(tree.postorder == post, "postorder \(tree.postorder), expected \(post)")
        for v in 0 ..< n {
            let below = pre.filter { w in w != v && Array(tree.ancestors(of: w)).contains(v) }
            check(Array(tree.descendants(of: v)) == below, "descendants of \(v)")
        }
        func lca(_ a: Int, _ b: Int) -> Int {
            var x = a, y = b
            while depth[x] > depth[y] { x = parent[x]! }
            while depth[y] > depth[x] { y = parent[y]! }
            while x != y { x = parent[x]!; y = parent[y]! }
            return x
        }
        for a in 0 ..< n {
            for b in 0 ..< n {
                let path = tree.path(from: a, to: b)
                check(path.source == a && path.target == b && Path(vertices: path.vertices, edges: path.edges, in: tree) != nil, "path \(a)→\(b): \(path)")
                check(path.length == depth[a] + depth[b] - 2 * depth[lca(a, b)], "path \(a)→\(b) is not the shortest")
            }
        }
        let arborescence = Arborescence(tree)
        check(arborescence.root == root && RootedTree(arborescence) == tree, "Arborescence(rooted)")
        for e in 0 ..< n - 1 {
            check(arborescence.source(ofEdgeAt: e) == parent[arborescence.target(ofEdgeAt: e)], "arborescence edge \(e) does not point away from the root")
        }
        for v in 0 ..< n {
            check(Array(arborescence.successors(of: v)) == Array(tree.children(of: v)), "successors of \(v)")
            check(Array(arborescence.predecessors(of: v)) == (parent[v].map { [$0] } ?? []), "predecessors of \(v)")
            check(arborescence.outEdges(of: v).allSatisfy { arborescence.source(ofEdgeAt: $0) == v }, "outEdges of \(v)")
            check(arborescence.inEdges(of: v).allSatisfy { arborescence.target(ofEdgeAt: $0) == v } && arborescence.inDegree(of: v) == (v == root ? 0 : 1), "inEdges of \(v)")
        }
        checkChecked(tree, arborescence, n)
        // The parent function rebuilds the same rooted tree.
        let parents = (0 ..< n).map { tree.parent(of: $0) }
        check(RootedTree(parents: parents) == tree && Arborescence(parents: parents) == arborescence, "init(parents:)")
    }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 9)
        let directedFlips = input.int(below: 4)
        var edges: [(Int, Int)] = []
        while !input.isEmpty, edges.count < 12 { edges.append((input.int(below: n), input.int(below: n))) }
        let (labels, cyclic) = components(n, edges)
        let componentCount = Set(labels).count
        let undirected = edges.map { UndirectedEdge($0.0, $0.1) }
        let isTree = !cyclic && componentCount == 1
        let isForest = !cyclic

        let tree = Tree(vertices: 0 ..< n, edges: undirected)
        check((tree != nil) == isTree, "Tree exists \(tree != nil), expected \(isTree)")
        let list = UndirectedAdjacencyList(vertices: 0 ..< n, edges: undirected)
        let collapsed = list.edgeCount == edges.count
        if collapsed {
            check(list.isTree == isTree && (Tree(list) != nil) == isTree, "isTree / Tree(list)")
            check((Forest(list) != nil) == isForest, "Forest(list)")
        }
        let forest = Forest(vertices: 0 ..< n, edges: undirected)
        check((forest != nil) == isForest, "Forest exists \(forest != nil), expected \(isForest)")
        if let forest {
            let trees = forest.trees
            check(trees.count == componentCount, "forest has \(trees.count) trees, expected \(componentCount)")
            for (t, tree) in trees.enumerated() {
                let members = (0 ..< n).filter { labels[$0] == t }
                check(Array(tree.vertices) == members, "tree \(t) of the forest: \(Array(tree.vertices)), expected \(members)")
                check(members.allSatisfy { forest.component(of: $0) == t }, "component(of:)")
                check(members.allSatisfy { (try? forest.component(checked: $0)) == t }, "component(checked:)")
                check(tree.edgeCount == members.count - 1, "tree \(t) edges")
            }
            for a in 0 ..< n {
                for b in 0 ..< n {
                    let path = forest.path(from: a, to: b)
                    check((path != nil) == (labels[a] == labels[b]), "forest path \(a)→\(b)")
                    if let path { check(Path(vertices: path.vertices, edges: path.edges, in: forest) != nil, "forest path \(a)→\(b) is not a path") }
                    do {
                        check(try forest.path(checkedFrom: a, to: b)?.edges == path?.edges, "forest path(checkedFrom: \(a), to: \(b))")
                    } catch {
                        check(false, "forest path(checkedFrom: \(a), to: \(b)) threw")
                    }
                }
                check((try? forest.degree(checked: a)) == forest.degree(of: a) && (try? forest.vertexIndex(checked: a)) == a, "forest degree(checked: \(a))")
                check((try? forest.neighbors(checked: a)).map(Array.init) == Array(forest.neighbors(of: a)) && (try? forest.incidentEdges(checked: a)) == forest.incidentEdges(of: a), "forest neighbors(checked: \(a))")
            }
            for x in outside(n) {
                check(missing { () throws(VertexNotFound) in try forest.component(checked: x) } && missing { () throws(VertexNotFound) in try forest.path(checkedFrom: 0, to: x) }, "forest component(checked: \(x))")
                check(missing { () throws(VertexNotFound) in try forest.degree(checked: x) } && missing { () throws(VertexNotFound) in try forest.neighbors(checked: x) }, "forest degree(checked: \(x))")
            }
        }
        if let tree {
            check(Array(tree.edges) == undirected, "tree edges keep their positions")
            // Graph laws.
            var degreeSum = 0
            for v in 0 ..< n {
                check(Array(tree.neighborIndices(ofIndex: v)) == tree.incidentEdges(of: v).map { tree.oppositeVertex(to: v, acrossEdgeAt: $0) }, "neighborIndices of \(v)")
                check(Array(tree.neighbors(of: v)) == Array(tree.neighborIndices(ofIndex: v)), "neighbors of \(v)")
                degreeSum += tree.degree(of: v)
            }
            check(degreeSum == 2 * tree.edgeCount, "degrees sum to 2m")
            // The same tree over String vertices: the linear search for n ≤ 8, the hash table for 9.
            let names = (0 ..< n).map { "v\($0)" }
            let named = Tree(vertices: names, edges: edges.map { UndirectedEdge(names[$0.0], names[$0.1]) })!
            let namedRooted = RootedTree(named, root: names[n - 1])
            for v in 0 ..< n {
                check((try? named.vertexIndex(checked: names[v])) == v && (try? named.degree(checked: names[v])) == tree.degree(of: v), "named vertexIndex(checked: \(v))")
                check((try? named.path(checkedFrom: names[0], to: names[v]))?.edges == tree.path(from: 0, to: v).edges, "named path(checkedFrom:to: \(v))")
                check((try? namedRooted.depth(checked: names[v])) == namedRooted.depth(of: names[v]), "named depth(checked: \(v))")
            }
            for x in ["", "v\(n)", "w0"] {
                check(missing { () throws(VertexNotFound) in try named.vertexIndex(checked: x) } && missing { () throws(VertexNotFound) in try namedRooted.parent(checked: x) }, "named vertexIndex(checked: \(x))")
            }
            for root in 0 ..< n { checkRooted(RootedTree(tree, root: root), n, edges, root) }
            if let code = tree.pruferSequence {
                check(Tree(pruferSequence: code) == tree, "Prüfer \(code) decodes to another tree")
                // 0..<n listed backward is ranked by value: the same code. The names rank by index,
                // so their code is the same one written with names.
                let backward = Tree(vertices: (0 ..< n).reversed(), edges: undirected)!
                check(backward.pruferSequence == code, "Prüfer of 0..<n listed backward \(backward.pruferSequence ?? []), in order \(code)")
                check(named.pruferSequence == code.map { names[$0] }, "named Prüfer \(named.pruferSequence ?? [])")
            } else {
                check(n == 1, "no Prüfer sequence for \(n) vertices")
            }
        }

        // Directed: the edges as given, a few flipped.
        var arcs = edges.map { DirectedEdge(from: $0.0, to: $0.1) }
        for k in 0 ..< min(directedFlips, arcs.count) { arcs[k] = DirectedEdge(from: arcs[k].target, to: arcs[k].source) }
        var incoming = [Int](repeating: 0, count: n)
        for arc in arcs { incoming[arc.target] += 1 }
        let roots = (0 ..< n).filter { incoming[$0] == 0 }
        let isArborescence = isTree && arcs.count == n - 1 && roots.count == 1 && incoming.allSatisfy { $0 <= 1 }
        let arborescence = Arborescence(vertices: 0 ..< n, edges: arcs)
        check((arborescence != nil) == isArborescence, "Arborescence exists \(arborescence != nil), expected \(isArborescence)")
        let digraph = AdjacencyList(vertices: 0 ..< n, edges: arcs)
        if digraph.edgeCount == arcs.count {
            check(digraph.isArborescence == isArborescence && (Arborescence(digraph) != nil) == isArborescence, "isArborescence / Arborescence(list)")
        }
        if let arborescence {
            check(arborescence.root == roots[0], "arborescence root")
            check(Array(arborescence.edges) == arcs, "arborescence edges keep their positions")
        }
    }
}
