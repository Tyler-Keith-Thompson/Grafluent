/// Boyer and Myrvold's edge-addition planarity algorithm ("On the Cutting Edge: Simplified O(n)
/// Planarity by Edge Addition", JGAA 8(3), 2004), run on an underlying simple graph in index space
/// only to find a Kuratowski subgraph: when it cannot embed a back edge, the state it stops in
/// isolates a subdivision of K₅ or K₃,₃ in linear time (`KuratowskiIsolation.swift`). It follows
/// the structure of Boyer's reference implementation (the edge-addition planarity suite): vertices
/// renumbered by depth-first index, a virtual root copy `c + n` of each tree edge's parent, edge
/// records in twin pairs on doubly linked adjacency lists, and short-circuit links around each
/// bicomponent's external face.
///
/// Simple edge `k` has edge records `2k` and `2k + 1`. On a tree edge, `2k` is the child record (in
/// the virtual root's list) and `2k + 1` the parent record (in the child's); on a back edge, `2k` is
/// the forward record (kept in the ancestor's forward list until embedded) and `2k + 1` the back
/// record.
@usableFromInline
struct _BoyerMyrvold: ~Copyable {
    typealias Buffer = UnsafeMutableBufferPointer<Int>

    static var none: Int { -1 }
    static var child: Int { 1 }
    static var parentType: Int { 2 }
    static var back: Int { 3 }
    static var forward: Int { 4 }

    var arena: _ScratchArena
    /// Vertices (renumbered by depth-first index) and simple edges.
    let n: Int
    let s: Int
    /// Per depth-first index: the vertex number in the input.
    let vertexOfIndex: Buffer
    // Vertex records, real (0 ..< n) and virtual (n ..< 2n): the first and last edge records, and
    // the two external face neighbours (`ext[2x + link]`).
    let firstEdge: Buffer
    let lastEdge: Buffer
    let ext: Buffer
    let vertexVisited: Buffer
    let mark: Buffer
    // Per real vertex.
    let parent: Buffer
    let treeEdge: Buffer
    let leastAncestor: Buffer
    let lowpoint: Buffer
    let pertinentEdge: Buffer
    let pertinentRoots: Buffer
    let futurePertinentChild: Buffer
    let childList: Buffer
    let fwdEdgeList: Buffer
    let visitedIndex: Buffer
    // Circular lists by child: the depth-first children of a vertex, and its pertinent roots.
    let childNext: Buffer
    let childPrevious: Buffer
    let rootNext: Buffer
    let rootPrevious: Buffer
    // Edge records.
    let neighbor: Buffer
    let nextEdge: Buffer
    let previousEdge: Buffer
    let edgeType: Buffer
    let inverted: Buffer
    /// Per simple edge: marked as part of the Kuratowski subgraph being isolated.
    let edgeVisited: Buffer
    /// Pairs: the merge stack of the Walkdown, and the isolator's work stack.
    var stack: [Int] = []
    /// The isolator's context.
    var context = _IsolatorContext()

    @usableFromInline
    init(_ graph: borrowing _UnderlyingSimpleGraph) {
        let n = graph.vertexCount
        let s = graph.simpleEdgeCount
        self.n = n
        self.s = s
        var arena = _ScratchArena(capacity: 30 * n + 11 * s + 8)
        vertexOfIndex = arena.take(n, repeating: -1)
        firstEdge = arena.take(2 * n, repeating: -1)
        lastEdge = arena.take(2 * n, repeating: -1)
        ext = arena.take(4 * n, repeating: -1)
        vertexVisited = arena.take(2 * n, repeating: 0)
        mark = arena.take(2 * n, repeating: 0)
        parent = arena.take(n, repeating: -1)
        treeEdge = arena.take(n, repeating: -1)
        leastAncestor = arena.take(n, repeating: 0)
        lowpoint = arena.take(n, repeating: 0)
        pertinentEdge = arena.take(n, repeating: -1)
        pertinentRoots = arena.take(n, repeating: -1)
        futurePertinentChild = arena.take(n, repeating: -1)
        childList = arena.take(n, repeating: -1)
        fwdEdgeList = arena.take(n, repeating: -1)
        visitedIndex = arena.take(n, repeating: n)
        childNext = arena.take(n, repeating: -1)
        childPrevious = arena.take(n, repeating: -1)
        rootNext = arena.take(n, repeating: -1)
        rootPrevious = arena.take(n, repeating: -1)
        neighbor = arena.take(2 * s, repeating: -1)
        nextEdge = arena.take(2 * s, repeating: -1)
        previousEdge = arena.take(2 * s, repeating: -1)
        edgeType = arena.take(2 * s, repeating: 0)
        inverted = arena.take(2 * s, repeating: 0)
        edgeVisited = arena.take(s, repeating: 0)
        // Depth-first search in index space: depth-first indices, parents and tree edges.
        let index = arena.take(n, repeating: -1)
        let cursor = arena.take(n, repeating: 0)
        let frames = arena.take(n, repeating: 0)
        self.arena = arena
        var next = 0
        graph.rowStart.withUnsafeBufferPointer { rowStart in
            graph.rowEdges.withUnsafeBufferPointer { rowEdges in
                graph.ends.withUnsafeBufferPointer { ends in
                    for root in 0 ..< n where index[root] == -1 {
                        index[root] = next
                        vertexOfIndex[next] = root
                        next += 1
                        frames[0] = root
                        cursor[root] = rowStart[root]
                        var top = 1
                        while top > 0 {
                            let v = frames[top - 1]
                            if cursor[v] == rowStart[v + 1] {
                                top -= 1
                                continue
                            }
                            let k = rowEdges[cursor[v]]
                            cursor[v] += 1
                            let w = ends[2 * k] == v ? ends[2 * k + 1] : ends[2 * k]
                            if index[w] == -1 {
                                index[w] = next
                                vertexOfIndex[next] = w
                                parent[next] = index[v]
                                treeEdge[next] = k
                                next += 1
                                cursor[w] = rowStart[w]
                                frames[top] = w
                                top += 1
                            }
                        }
                    }
                    // The tree edges as singleton bicomponents: child record in the virtual root,
                    // parent record in the child.
                    for c in 0 ..< n where parent[c] != -1 {
                        let k = treeEdge[c]
                        let root = c + n
                        neighbor[2 * k] = c
                        edgeType[2 * k] = Self.child
                        neighbor[2 * k + 1] = root
                        edgeType[2 * k + 1] = Self.parentType
                        firstEdge[root] = 2 * k
                        lastEdge[root] = 2 * k
                        firstEdge[c] = 2 * k + 1
                        lastEdge[c] = 2 * k + 1
                        ext[2 * root] = c
                        ext[2 * root + 1] = c
                        ext[2 * c] = root
                        ext[2 * c + 1] = root
                        // Children in increasing depth-first index.
                        let p = parent[c]
                        let head = childList[p]
                        if head == -1 {
                            childList[p] = c
                            childNext[c] = c
                            childPrevious[c] = c
                        } else {
                            let last = childPrevious[head]
                            childPrevious[head] = c
                            childNext[c] = head
                            childPrevious[c] = last
                            childNext[last] = c
                        }
                    }
                    // Back edges, from each descendant in increasing depth-first index, so each
                    // ancestor's forward list is sorted by descendant.
                    for d in 0 ..< n {
                        leastAncestor[d] = d
                        let v = vertexOfIndex[d]
                        for i in rowStart[v] ..< rowStart[v + 1] {
                            let k = rowEdges[i]
                            let a = index[ends[2 * k] == v ? ends[2 * k + 1] : ends[2 * k]]
                            guard a < d && k != treeEdge[d] else { continue }
                            neighbor[2 * k] = d
                            edgeType[2 * k] = Self.forward
                            neighbor[2 * k + 1] = a
                            edgeType[2 * k + 1] = Self.back
                            if a < leastAncestor[d] { leastAncestor[d] = a }
                            let head = fwdEdgeList[a]
                            if head == -1 {
                                fwdEdgeList[a] = 2 * k
                                nextEdge[2 * k] = 2 * k
                                previousEdge[2 * k] = 2 * k
                            } else {
                                let last = previousEdge[head]
                                previousEdge[head] = 2 * k
                                nextEdge[2 * k] = head
                                previousEdge[2 * k] = last
                                nextEdge[last] = 2 * k
                            }
                        }
                    }
                }
            }
        }
        // Lowpoints, children before parents.
        var v = n - 1
        while v >= 0 {
            var low = leastAncestor[v]
            var c = childList[v]
            while c != -1 {
                if lowpoint[c] < low { low = lowpoint[c] }
                c = nextChild(v, c)
            }
            lowpoint[v] = low
            futurePertinentChild[v] = childList[v]
            v -= 1
        }
    }

    // MARK: Accessors

    @inline(__always)
    func edge(_ v: Int, link: Int) -> Int { link == 0 ? firstEdge[v] : lastEdge[v] }

    @inline(__always)
    func setEdge(_ v: Int, link: Int, _ e: Int) {
        if link == 0 { firstEdge[v] = e } else { lastEdge[v] = e }
    }

    /// The edge record beside `e` in its list: link 0 is the next, link 1 the previous.
    @inline(__always)
    func adjacent(_ e: Int, link: Int) -> Int { link == 0 ? nextEdge[e] : previousEdge[e] }

    @inline(__always)
    func setAdjacent(_ e: Int, link: Int, _ f: Int) {
        if link == 0 { nextEdge[e] = f } else { previousEdge[e] = f }
    }

    /// The vertex whose list holds edge record `e`.
    @inline(__always)
    func owner(_ e: Int) -> Int { neighbor[e ^ 1] }

    @inline(__always)
    func nextCircular(_ e: Int) -> Int { nextEdge[e] != -1 ? nextEdge[e] : firstEdge[owner(e)] }

    @inline(__always)
    func previousCircular(_ e: Int) -> Int { previousEdge[e] != -1 ? previousEdge[e] : lastEdge[owner(e)] }

    /// The real vertex a virtual root is a copy of.
    @inline(__always)
    func vertex(ofRoot root: Int) -> Int { parent[root - n] }

    @inline(__always)
    func nextChild(_ v: Int, _ c: Int) -> Int {
        let next = childNext[c]
        return next == childList[v] ? -1 : next
    }

    /// Whether the child `c` is still separated from its parent: its virtual root is in use.
    @inline(__always)
    func isSeparated(_ c: Int) -> Bool { firstEdge[c + n] != -1 }

    @inline(__always)
    func isPertinent(_ w: Int) -> Bool { pertinentEdge[w] != -1 || pertinentRoots[w] != -1 }

    @inline(__always)
    func isFuturePertinent(_ w: Int, _ v: Int) -> Bool {
        if leastAncestor[w] < v { return true }
        let c = futurePertinentChild[w]
        return c != -1 && lowpoint[c] < v
    }

    @inline(__always)
    func isInactive(_ w: Int, _ v: Int) -> Bool { !isPertinent(w) && !isFuturePertinent(w, v) }

    /// Advances `w`'s future-pertinent child past children that cannot connect below `v` any more,
    /// or that have been merged into `w`'s bicomponent. Amortized O(1).
    @inline(__always)
    func updateFuturePertinentChild(_ w: Int, _ v: Int) {
        while futurePertinentChild[w] != -1 {
            let c = futurePertinentChild[w]
            if lowpoint[c] >= v || !isSeparated(c) {
                futurePertinentChild[w] = nextChild(w, c)
            } else {
                break
            }
        }
    }

    // MARK: Pertinent root lists

    func appendRoot(_ v: Int, child c: Int) {
        let head = pertinentRoots[v]
        if head == -1 {
            rootNext[c] = c
            rootPrevious[c] = c
            pertinentRoots[v] = c
        } else {
            let last = rootPrevious[head]
            rootPrevious[head] = c
            rootNext[c] = head
            rootPrevious[c] = last
            rootNext[last] = c
        }
    }

    func prependRoot(_ v: Int, child c: Int) {
        appendRoot(v, child: c)
        pertinentRoots[v] = c
    }

    func deleteRoot(_ v: Int, child c: Int) {
        let head = pertinentRoots[v]
        if rootNext[head] == head {
            rootNext[head] = -1
            rootPrevious[head] = -1
            pertinentRoots[v] = -1
        } else {
            let previous = rootPrevious[c], next = rootNext[c]
            rootNext[previous] = next
            rootPrevious[next] = previous
            rootNext[c] = -1
            rootPrevious[c] = -1
            if head == c { pertinentRoots[v] = next }
        }
    }

    // MARK: The algorithm

    /// Embeds the back edges from each vertex to its descendants, in decreasing depth-first index.
    /// Returns the simple edges of a Kuratowski subgraph, or nil when the graph is planar.
    @usableFromInline
    mutating func findKuratowskiSubgraph() -> [Int]? {
        var v = n - 1
        while v >= 0 {
            // Walkup: pertinence for step v.
            let head = fwdEdgeList[v]
            if head != -1 {
                var e = head
                repeat {
                    walkUp(v, e)
                    e = nextEdge[e]
                } while e != head
            }
            pertinentRoots[v] = -1
            // Walkdown: each pertinent child subtree.
            var c = childList[v]
            while c != -1 {
                if pertinentRoots[c] != -1 || pertinentEdge[c] != -1 {
                    if let witness = walkDown(v, root: c + n) { return witness }
                }
                c = nextChild(v, c)
            }
            v -= 1
        }
        return nil
    }

    /// Marks the descendant end of back edge `e` (a forward record of `v`) pertinent, and records
    /// the bicomponent roots between it and `v` as pertinent, walking each external face both ways
    /// at once so the cost is the shorter side.
    mutating func walkUp(_ v: Int, _ e: Int) {
        let w = neighbor[e]
        var zig = w, zag = w, zigPrevious = 1, zagPrevious = 0
        pertinentEdge[w] = e
        while zig != v {
            var nextZig = ext[2 * zig + (1 ^ zigPrevious)]
            var nextZag = -1
            var root = -1
            if nextZig >= n {
                if visitedIndex[zig] == v { break }
                root = nextZig
                nextZag = ext[2 * root + (ext[2 * root] == zig ? 1 : 0)]
                if visitedIndex[nextZag] == v { break }
            } else {
                nextZag = ext[2 * zag + (1 ^ zagPrevious)]
                if nextZag >= n {
                    if visitedIndex[zag] == v { break }
                    root = nextZag
                    nextZig = ext[2 * root + (ext[2 * root] == zag ? 1 : 0)]
                    if visitedIndex[nextZig] == v { break }
                } else {
                    if visitedIndex[zig] == v || visitedIndex[zag] == v { break }
                }
            }
            visitedIndex[zig] = v
            visitedIndex[zag] = v
            if root == -1 {
                zigPrevious = ext[2 * nextZig] == zig ? 0 : 1
                zig = nextZig
                zagPrevious = ext[2 * nextZag] == zag ? 0 : 1
                zag = nextZag
            } else {
                let c = root - n
                zig = parent[c]
                zag = zig
                zigPrevious = 1
                zagPrevious = 0
                // Roots that are only pertinent go first, future-pertinent ones last.
                if lowpoint[c] < v {
                    appendRoot(zig, child: c)
                } else {
                    prependRoot(zig, child: c)
                }
            }
        }
    }

    /// Walks down both external face paths of the bicomponent at `root` (a virtual copy of `v`),
    /// embedding each back edge to `v` it reaches and merging the bicomponents it descends through.
    /// Returns a Kuratowski subgraph when it is blocked.
    mutating func walkDown(_ v: Int, root: Int) -> [Int]? {
        let rootChild = root - n
        stack.removeAll(keepingCapacity: true)
        for rootSide in 0 ... 1 {
            var w = ext[2 * root + rootSide]
            var wPrevious = ext[2 * w + 1] == root ? 1 : 0
            while w != root {
                let e = pertinentEdge[w]
                if e != -1 {
                    if !stack.isEmpty { mergeBicomponents() }
                    embedBackEdge(rootSide: rootSide, root: root, w, wPrevious)
                    pertinentEdge[w] = -1
                }
                if pertinentRoots[w] != -1 {
                    // Descend to the first pertinent child bicomponent of w.
                    stack.append(w)
                    stack.append(wPrevious)
                    let r = pertinentRoots[w] + n
                    let x = ext[2 * r], xPrevious = ext[2 * x + 1] == r ? 1 : 0
                    let y = ext[2 * r + 1], yPrevious = ext[2 * y] == r ? 0 : 1
                    updateFuturePertinentChild(x, v)
                    updateFuturePertinentChild(y, v)
                    if isPertinent(x) && !isFuturePertinent(x, v) {
                        w = x
                        wPrevious = xPrevious
                        stack.append(r)
                        stack.append(0)
                    } else if isPertinent(y) && !isFuturePertinent(y, v) {
                        w = y
                        wPrevious = yPrevious
                        stack.append(r)
                        stack.append(1)
                    } else if isPertinent(x) {
                        w = x
                        wPrevious = xPrevious
                        stack.append(r)
                        stack.append(0)
                    } else if isPertinent(y) {
                        w = y
                        wPrevious = yPrevious
                        stack.append(r)
                        stack.append(1)
                    } else {
                        // Both sides of the child bicomponent are blocked.
                        return isolateKuratowskiSubgraph(v, root: r)
                    }
                } else {
                    updateFuturePertinentChild(w, v)
                    if isFuturePertinent(w, v) {
                        // A stopping vertex: short-circuit the external face from the root to it,
                        // keeping at least three vertices on that face.
                        if ext[2 * root + (1 ^ rootSide)] == w {
                            let x = w
                            w = ext[2 * w + wPrevious]
                            wPrevious = ext[2 * w] == x ? 1 : 0
                        }
                        if w != root {
                            ext[2 * root + rootSide] = w
                            ext[2 * w + wPrevious] = root
                        }
                        break
                    }
                    // Inactive: pass over it.
                    let x = ext[2 * w + (1 ^ wPrevious)]
                    wPrevious = ext[2 * x] == w ? 0 : 1
                    w = x
                }
            }
        }
        // Blocked if a back edge from v into this child's subtree is still unembedded.
        let e = fwdEdgeList[v]
        if e != -1 && rootChild < neighbor[e] {
            let following = nextChild(v, rootChild)
            if following == -1 || following > neighbor[e] {
                return isolateKuratowskiSubgraph(v, root: root)
            }
        }
        return nil
    }

    /// Adds the back edge from the root (a copy of `v`) to `w`, on the root's side `rootSide` and
    /// `w`'s link `wPrevious`, and makes the two neighbours on the external face.
    mutating func embedBackEdge(rootSide: Int, root: Int, _ w: Int, _ wPrevious: Int) {
        let forward = pertinentEdge[w]
        let back = forward ^ 1
        let v = vertex(ofRoot: root)
        if fwdEdgeList[v] == forward {
            fwdEdgeList[v] = nextEdge[forward]
            if fwdEdgeList[v] == forward { fwdEdgeList[v] = -1 }
        }
        nextEdge[previousEdge[forward]] = nextEdge[forward]
        previousEdge[nextEdge[forward]] = previousEdge[forward]
        // The forward record joins the root's list on rootSide.
        setAdjacent(forward, link: 1 ^ rootSide, -1)
        setAdjacent(forward, link: rootSide, edge(root, link: rootSide))
        setAdjacent(edge(root, link: rootSide), link: 1 ^ rootSide, forward)
        setEdge(root, link: rootSide, forward)
        // The back record joins w's list on wPrevious.
        setAdjacent(back, link: 1 ^ wPrevious, -1)
        setAdjacent(back, link: wPrevious, edge(w, link: wPrevious))
        setAdjacent(edge(w, link: wPrevious), link: 1 ^ wPrevious, back)
        setEdge(w, link: wPrevious, back)
        neighbor[back] = root
        ext[2 * root + rootSide] = w
        ext[2 * w + wPrevious] = root
    }

    /// Reverses the orientation of one vertex: its list, its first and last records, and its
    /// external face links.
    func invertVertex(_ w: Int) {
        var e = firstEdge[w]
        while e != -1 {
            let next = nextEdge[e]
            nextEdge[e] = previousEdge[e]
            previousEdge[e] = next
            e = next
        }
        let first = firstEdge[w]
        firstEdge[w] = lastEdge[w]
        lastEdge[w] = first
        let link = ext[2 * w]
        ext[2 * w] = ext[2 * w + 1]
        ext[2 * w + 1] = link
    }

    /// Merges virtual root `r` into its real vertex `w`, joining their lists so that `w`'s link
    /// `wPrevious` and `r`'s opposite link become adjacent.
    func mergeVertex(_ w: Int, _ wPrevious: Int, _ r: Int) {
        var e = firstEdge[r]
        while e != -1 {
            neighbor[e ^ 1] = w
            e = nextEdge[e]
        }
        let eW = edge(w, link: wPrevious)
        let eR = edge(r, link: 1 ^ wPrevious)
        let eExt = edge(r, link: wPrevious)
        if eW != -1 {
            setAdjacent(eW, link: 1 ^ wPrevious, eR)
            setAdjacent(eR, link: wPrevious, eW)
        } else {
            setEdge(w, link: 1 ^ wPrevious, eR)
            setAdjacent(eR, link: wPrevious, -1)
        }
        setEdge(w, link: wPrevious, eExt)
        setAdjacent(eExt, link: 1 ^ wPrevious, -1)
        firstEdge[r] = -1
        lastEdge[r] = -1
        vertexVisited[r] = 0
        mark[r] = 0
    }

    /// Merges the bicomponents whose cut vertices the Walkdown descended through, from the deepest
    /// up, flipping a child bicomponent (lazily, by the sign on its root edge) when it was entered
    /// and left on the same side.
    mutating func mergeBicomponents() {
        while !stack.isEmpty {
            let rOut = stack.removeLast()
            let r = stack.removeLast()
            let zPrevious = stack.removeLast()
            let z = stack.removeLast()
            let extVertex = ext[2 * r + (1 ^ rOut)]
            ext[2 * z + zPrevious] = extVertex
            if ext[2 * extVertex] == ext[2 * extVertex + 1] {
                ext[2 * extVertex + rOut] = z
            } else {
                ext[2 * extVertex + (ext[2 * extVertex] == r ? 0 : 1)] = z
            }
            if zPrevious == rOut {
                if firstEdge[r] != lastEdge[r] { invertVertex(r) }
                var e = firstEdge[r]
                while e != -1 {
                    if edgeType[e] == Self.child {
                        inverted[e] ^= 1
                        break
                    }
                    e = nextEdge[e]
                }
            }
            let c = r - n
            deleteRoot(z, child: c)
            if c == futurePertinentChild[z] {
                futurePertinentChild[z] = nextChild(z, c)
            }
            mergeVertex(z, zPrevious, r)
        }
    }
}
