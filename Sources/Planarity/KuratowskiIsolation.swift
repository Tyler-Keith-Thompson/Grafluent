/// Which of Boyer and Myrvold's non-planarity minors the blocked state shows, and the vertices
/// that pin it: `v` the vertex being processed, `r` the root of the blocked bicomponent, `x` and
/// `y` the stopping vertices on its two external face paths, `w` a pertinent vertex between them,
/// `px` and `py` where the x–y path meets the external face, `z` a vertex for minors D and E; `ux`,
/// `dx` (and so on) the ends of an unembedded edge joining `x` (and so on) to an ancestor of `v`,
/// and `dw` the descendant end of an unembedded edge to `v`.
struct _IsolatorContext {
    enum Minor { case none, a, b, c, d, e }
    var minor = Minor.none
    var v = -1, r = -1, x = -1, y = -1, w = -1, px = -1, py = -1, z = -1
    var ux = -1, dx = -1, uy = -1, dy = -1, dw = -1, uz = -1, dz = -1
}

/// Marks on the external face of the blocked bicomponent, relative to x, y and w.
private enum _FaceMark {
    static var none: Int { 0 }
    /// Between r and x.
    static var highRXW: Int { 1 }
    /// x, or between x and w.
    static var lowRXW: Int { 2 }
    /// Between r and y.
    static var highRYW: Int { 3 }
    /// y, or between y and w.
    static var lowRYW: Int { 4 }
}

extension _BoyerMyrvold {
    /// Isolates a subdivision of K₅ or K₃,₃ from the state the Walkdown was blocked in at the
    /// bicomponent rooted at `r` (Boyer and Myrvold, section 6; the cases follow the reference
    /// implementation's isolator): minors A–D give K₃,₃, minor E gives K₅ or, in its subcases E1–E4,
    /// K₃,₃. Each case marks external face paths, the x–y path, depth-first tree paths and a few
    /// unembedded edges; the marked edges are the subgraph. Linear time.
    mutating func isolateKuratowskiSubgraph(_ v: Int, root r: Int) -> [Int] {
        stack.removeAll(keepingCapacity: true)
        clearMarks()
        chooseMinor(v, r)
        initializeContext()
        switch context.minor {
        case .a: isolateMinorA()
        case .b: isolateMinorB()
        case .c: isolateMinorC()
        case .d: isolateMinorD()
        case .e: isolateMinorE()
        case .none: preconditionFailure("Planarity: no non-planarity minor found")
        }
        var witness: [Int] = []
        for k in 0 ..< s where edgeVisited[k] != 0 { witness.append(k) }
        return witness
    }

    func clearMarks() {
        for x in 0 ..< 2 * n {
            vertexVisited[x] = 0
            mark[x] = 0
        }
        for k in 0 ..< s { edgeVisited[k] = 0 }
    }

    @inline(__always)
    func markEdge(_ e: Int) { edgeVisited[e >> 1] = 1 }

    @inline(__always)
    func isEdgeMarked(_ e: Int) -> Bool { edgeVisited[e >> 1] != 0 }

    // MARK: Choosing the minor

    mutating func chooseMinor(_ v: Int, _ r: Int) {
        context = _IsolatorContext()
        context.v = v
        context.r = r
        orientVerticesInBicomponent(r)
        findActiveVertices()
        context.w = findPertinentVertex()
        precondition(context.w != -1, "Planarity: no pertinent vertex below the stopping vertices")
        // The blocked bicomponent is not rooted at a copy of v.
        if vertex(ofRoot: r) != v {
            context.minor = .a
            return
        }
        markExternalFace()
        // w has a pertinent child bicomponent that is also future pertinent.
        let w = context.w
        if pertinentRoots[w] != -1 && lowpoint[rootPrevious[pertinentRoots[w]]] < v {
            context.minor = .b
            return
        }
        markClosestXYPath()
        precondition(context.py != -1, "Planarity: no x–y path")
        // An attachment point of the x–y path above x or y.
        if mark[context.px] == _FaceMark.highRXW || mark[context.py] == _FaceMark.highRYW {
            context.minor = .c
            return
        }
        // A path from an inner vertex of the x–y path up to r.
        markZToRPath()
        if context.z != -1 {
            context.minor = .d
            return
        }
        // A future-pertinent vertex below the x–y path.
        let z = findFuturePertinenceBelowXYPath()
        precondition(z != -1, "Planarity: no future-pertinent vertex below the x–y path")
        context.z = z
        context.minor = .e
    }

    /// Gives every vertex of the bicomponent at `r` the root's orientation, from the signs on the
    /// tree edges, leaving the signs in place.
    mutating func orientVerticesInBicomponent(_ r: Int) {
        let bottom = stack.count
        stack.append(r)
        stack.append(0)
        while stack.count > bottom {
            let flip = stack.removeLast()
            let w = stack.removeLast()
            if flip != 0 { invertVertex(w) }
            var e = firstEdge[w]
            while e != -1 {
                if edgeType[e] == Self.child {
                    stack.append(neighbor[e])
                    stack.append(flip ^ inverted[e])
                }
                e = nextEdge[e]
            }
        }
    }

    /// The vertex after `current` on the external face, leaving by the link not used to arrive
    /// (`previous`, updated to the link used to arrive at the result). This follows the true
    /// external face through the first and last edge records, not the short-circuit links.
    func neighborOnExternalFace(_ current: Int, _ previous: inout Int) -> Int {
        let e = edge(current, link: 1 ^ previous)
        let next = neighbor[e]
        if firstEdge[next] != lastEdge[next] {
            previous = (e ^ 1) == firstEdge[next] ? 0 : 1
        }
        return next
    }

    /// The first active vertex on each external face path from the root: x and y.
    mutating func findActiveVertices() {
        let v = context.v
        var xPrevious = 1, yPrevious = 0
        var x = neighborOnExternalFace(context.r, &xPrevious)
        var y = neighborOnExternalFace(context.r, &yPrevious)
        updateFuturePertinentChild(x, v)
        while isInactive(x, v) {
            x = neighborOnExternalFace(x, &xPrevious)
            updateFuturePertinentChild(x, v)
        }
        updateFuturePertinentChild(y, v)
        while isInactive(y, v) {
            y = neighborOnExternalFace(y, &yPrevious)
            updateFuturePertinentChild(y, v)
        }
        context.x = x
        context.y = y
    }

    /// A pertinent vertex on the lower external face path from x to y.
    func findPertinentVertex() -> Int {
        var previous = 1
        var w = neighborOnExternalFace(context.x, &previous)
        while w != context.y {
            if isPertinent(w) { return w }
            w = neighborOnExternalFace(w, &previous)
        }
        return -1
    }

    /// Marks the external face vertices: high or low, on the x or the y side of w.
    func markExternalFace() {
        var previous = 1
        var z = neighborOnExternalFace(context.r, &previous)
        var type = _FaceMark.highRXW
        while z != context.w {
            if z == context.x { type = _FaceMark.lowRXW }
            mark[z] = type
            z = neighborOnExternalFace(z, &previous)
        }
        previous = 0
        z = neighborOnExternalFace(context.r, &previous)
        type = _FaceMark.highRYW
        while z != context.w {
            if z == context.y { type = _FaceMark.lowRYW }
            mark[z] = type
            z = neighborOnExternalFace(z, &previous)
        }
    }

    // MARK: The x–y path

    /// Detaches edge record `e` from its list, keeping its own links so it can be restored.
    func detachRecord(_ e: Int) {
        let next = nextEdge[e], previous = previousEdge[e]
        let v = owner(e)
        if next != -1 { previousEdge[next] = previous } else { lastEdge[v] = previous }
        if previous != -1 { nextEdge[previous] = next } else { firstEdge[v] = next }
    }

    func restoreRecord(_ e: Int) {
        let next = nextEdge[e], previous = previousEdge[e]
        let v = owner(e)
        if next != -1 { previousEdge[next] = e } else { lastEdge[v] = e }
        if previous != -1 { nextEdge[previous] = e } else { firstEdge[v] = e }
    }

    /// Hides every edge of `vertex` but its first and last, pushing each.
    mutating func hideInternalEdges(_ vertex: Int) {
        var e = firstEdge[vertex]
        if e == lastEdge[vertex] { return }
        e = nextEdge[e]
        while e != lastEdge[vertex] {
            stack.append(e)
            detachRecord(e)
            detachRecord(e ^ 1)
            e = nextEdge[e]
        }
    }

    mutating func restoreHiddenEdges(_ bottom: Int) {
        while stack.count > bottom {
            let e = stack.removeLast()
            restoreRecord(e ^ 1)
            restoreRecord(e)
        }
    }

    /// Pops visited vertex–edge pairs back to `z` (or all of them, for −1), unmarking them.
    mutating func popAndUnmark(_ z: Int, _ bottom: Int) {
        while stack.count > bottom {
            let vertex = stack.removeLast()
            if vertex == z {
                stack.append(vertex)
                break
            }
            let e = stack.removeLast()
            vertexVisited[vertex] = 0
            edgeVisited[e >> 1] = 0
        }
    }

    /// Marks the x–y path closest to the root: with the root's inner edges hidden, walks the
    /// proper face at the root, discarding detours (loops back to a visited vertex, and everything
    /// before the last x-side attachment point), until it reaches the y side.
    mutating func markClosestXYPath() {
        let r = context.r
        context.px = -1
        context.py = -1
        let bottom1 = stack.count
        hideInternalEdges(r)
        let bottom2 = stack.count
        var z = r
        var e = lastEdge[r]
        while mark[z] != _FaceMark.highRYW && mark[z] != _FaceMark.lowRYW {
            e = previousCircular(e)
            z = neighbor[e]
            e ^= 1
            if vertexVisited[z] != 0 {
                popAndUnmark(z, bottom2)
            } else {
                if z == context.w {
                    popAndUnmark(-1, bottom2)
                    break
                }
                if mark[z] == _FaceMark.highRXW || mark[z] == _FaceMark.lowRXW {
                    context.px = z
                    popAndUnmark(-1, bottom2)
                }
                stack.append(e)
                stack.append(z)
                vertexVisited[z] = 1
                if z != context.px { markEdge(e) }
                if mark[z] == _FaceMark.highRYW || mark[z] == _FaceMark.lowRYW {
                    context.py = z
                    break
                }
            }
        }
        stack.removeSubrange(bottom2...)
        restoreHiddenEdges(bottom1)
        if context.py == -1 { context.px = -1 }
    }

    /// With the x–y path marked: finds an inner vertex z of it with a path to the root that avoids
    /// it and the external face, and marks that path.
    mutating func markZToRPath() {
        let r = context.r, px = context.px, py = context.py
        context.z = -1
        var next = lastEdge[px]
        while next != firstEdge[px] {
            if isEdgeMarked(next) { break }
            next = previousEdge[next]
        }
        precondition(isEdgeMarked(next), "Planarity: the x–y path does not leave its attachment point")
        var previous = next ^ 1
        while isEdgeMarked(next) {
            previous = next ^ 1
            next = previousCircular(previous)
        }
        previous = next ^ 1
        var z = neighbor[previous]
        if z == py { return }
        context.z = z
        while z != r {
            precondition(mark[z] == _FaceMark.none, "Planarity: the path to the root reached the external face")
            z = neighbor[next]
            markEdge(next)
            vertexVisited[z] = 1
            next = previousCircular(previous)
            previous = next ^ 1
        }
    }

    /// A future-pertinent vertex on the external face between the x–y path's attachment points.
    func findFuturePertinenceBelowXYPath() -> Int {
        let v = context.v
        var previous = 1
        var z = neighborOnExternalFace(context.px, &previous)
        while z != context.py {
            updateFuturePertinentChild(z, v)
            if isFuturePertinent(z, v) { return z }
            z = neighborOnExternalFace(z, &previous)
        }
        return -1
    }

    // MARK: Unembedded edges

    mutating func initializeContext() {
        var c = context
        (c.ux, c.dx) = unembeddedEdgeToAncestor(c.x)
        (c.uy, c.dy) = unembeddedEdgeToAncestor(c.y)
        if c.minor == .b {
            let subtree = rootPrevious[pertinentRoots[c.w]]
            c.uz = lowpoint[subtree]
            c.dw = unembeddedEdgeToSubtree(c.v, subtree)
            c.dz = unembeddedEdgeToSubtree(c.uz, subtree)
        } else {
            c.dw = pertinentEdge[c.w] != -1 ? c.w : unembeddedEdgeToSubtree(c.v, pertinentRoots[c.w])
            if c.minor == .e { (c.uz, c.dz) = unembeddedEdgeToAncestor(c.z) }
        }
        precondition(c.dx != -1 && c.dy != -1 && c.dw != -1 && (c.minor != .b || c.dz != -1) && (c.minor != .e || c.dz != -1),
                     "Planarity: an unembedded edge is missing")
        context = c
    }

    /// The least ancestor of `v` joined by an unembedded edge to `cutVertex` or to a descendant in a
    /// separated child subtree, and that descendant.
    func unembeddedEdgeToAncestor(_ cutVertex: Int) -> (ancestor: Int, descendant: Int) {
        var ancestor = leastAncestor[cutVertex]
        var found = -1
        var c = futurePertinentChild[cutVertex]
        while c != -1 {
            if isSeparated(c) && ancestor > lowpoint[c] {
                ancestor = lowpoint[c]
                found = c
            }
            c = nextChild(cutVertex, c)
        }
        if found == -1 { return (ancestor, cutVertex) }
        return (ancestor, unembeddedEdgeToSubtree(ancestor, found))
    }

    /// A descendant of `subtree` joined to `ancestor` by an unembedded edge (the least one), or −1.
    func unembeddedEdgeToSubtree(_ ancestor: Int, _ subtree: Int) -> Int {
        let head = fwdEdgeList[ancestor]
        guard head != -1 else { return -1 }
        var descendant = -1
        var e = head
        repeat {
            let d = neighbor[e]
            if d >= subtree && (descendant == -1 || d < descendant) { descendant = d }
            e = nextEdge[e]
        } while e != head
        guard descendant != -1 else { return -1 }
        var z = descendant
        while z != subtree {
            z = parent[z]
            if z == -1 { return -1 }
        }
        return descendant
    }

    // MARK: Marking

    /// Marks the external face path from `start` to `end`, leaving each vertex by its first link.
    func markPathAlongExternalFace(_ start: Int, _ end: Int) {
        vertexVisited[start] = 1
        var z = start
        var previous = 1
        repeat {
            z = neighborOnExternalFace(z, &previous)
            markEdge(edge(z, link: previous))
            vertexVisited[z] = 1
        } while z != end
    }

    /// Marks the tree path from `descendant` (a virtual root stands for its real vertex) up to
    /// `ancestor`.
    func markTreePath(_ ancestor: Int, _ descendant: Int) {
        var d = descendant >= n ? vertex(ofRoot: descendant) : descendant
        while d != ancestor {
            precondition(d != -1, "Planarity: not an ancestor")
            edgeVisited[treeEdge[d]] = 1
            d = parent[d]
        }
    }

    func markTreePathsToDescendants() {
        let c = context
        markTreePath(c.x, c.dx)
        markTreePath(c.y, c.dy)
        if c.dw != -1 { markTreePath(c.w, c.dw) }
        if c.dz != -1 { markTreePath(c.w, c.dz) }
    }

    /// Marks the unembedded edge from `ancestor` to `descendant`: a forward record of `ancestor`.
    func markUnembeddedEdge(_ ancestor: Int, _ descendant: Int) {
        let head = fwdEdgeList[ancestor]
        var e = head
        while e != -1 {
            if neighbor[e] == descendant {
                markEdge(e)
                return
            }
            e = nextEdge[e]
            if e == head { e = -1 }
        }
        preconditionFailure("Planarity: no unembedded edge from \(ancestor) to \(descendant)")
    }

    func markUnembeddedEdges() {
        let c = context
        markUnembeddedEdge(c.ux, c.dx)
        markUnembeddedEdge(c.uy, c.dy)
        if c.dw != -1 { markUnembeddedEdge(c.v, c.dw) }
        if c.dz != -1 { markUnembeddedEdge(c.uz, c.dz) }
    }

    // MARK: The minors

    func isolateMinorA() {
        let c = context
        markPathAlongExternalFace(c.r, c.r)
        markTreePath(Swift.min(c.ux, c.uy), c.r)
        markTreePathsToDescendants()
        markUnembeddedEdges()
    }

    func isolateMinorB() {
        let c = context
        markPathAlongExternalFace(c.r, c.r)
        markTreePath(Swift.min(c.ux, c.uy, c.uz), Swift.max(c.ux, c.uy, c.uz))
        markTreePathsToDescendants()
        markUnembeddedEdges()
    }

    func isolateMinorC() {
        let c = context
        if mark[c.px] == _FaceMark.highRXW {
            let highY = mark[c.py] == _FaceMark.highRYW ? c.py : c.y
            markPathAlongExternalFace(c.r, highY)
        } else {
            markPathAlongExternalFace(c.x, c.r)
        }
        markTreePathsToDescendants()
        markTreePath(Swift.min(c.ux, c.uy), c.r)
        markUnembeddedEdges()
    }

    func isolateMinorD() {
        let c = context
        markPathAlongExternalFace(c.x, c.y)
        markTreePath(Swift.min(c.ux, c.uy), c.r)
        markTreePathsToDescendants()
        markUnembeddedEdges()
    }

    mutating func isolateMinorE() {
        let c = context
        // E1: the future-pertinent vertex below the x–y path is not w; reduce to minor C.
        if c.z != c.w {
            if mark[c.z] == _FaceMark.lowRXW {
                mark[c.px] = _FaceMark.highRXW
                context.x = c.z
                context.ux = c.uz
                context.dx = c.dz
            } else if mark[c.z] == _FaceMark.lowRYW {
                mark[c.py] = _FaceMark.highRYW
                context.y = c.z
                context.uy = c.uz
                context.dy = c.dz
            } else {
                preconditionFailure("Planarity: minor E1 without a low vertex")
            }
            context.z = -1
            context.uz = -1
            context.dz = -1
            context.minor = .c
            isolateMinorC()
            return
        }
        // E2: z's ancestor connection is below both of x's and y's; reduce to minor A with v = uz.
        if c.uz > Swift.max(c.ux, c.uy) {
            clearMarks()
            context.v = c.uz
            context.dw = c.dz
            context.z = -1
            context.uz = -1
            context.dz = -1
            context.minor = .a
            isolateMinorA()
            return
        }
        // E3.
        if c.uz < Swift.max(c.ux, c.uy) && c.ux != c.uy {
            if c.ux < c.uy {
                markPathAlongExternalFace(c.r, c.px)
                markPathAlongExternalFace(c.w, c.y)
            } else {
                markPathAlongExternalFace(c.x, c.w)
                markPathAlongExternalFace(c.py, c.r)
            }
            markTreePath(Swift.min(c.ux, c.uy, c.uz), c.r)
            markTreePathsToDescendants()
            markUnembeddedEdges()
            return
        }
        // E4.
        if c.x != c.px || c.y != c.py {
            if c.px != c.x {
                markPathAlongExternalFace(c.r, c.w)
                markPathAlongExternalFace(c.py, c.r)
            } else {
                markPathAlongExternalFace(c.r, c.px)
                markPathAlongExternalFace(c.w, c.r)
            }
            markTreePath(Swift.min(c.ux, c.uy, c.uz), Swift.max(c.ux, c.uy, c.uz))
            markTreePathsToDescendants()
            markUnembeddedEdges()
            return
        }
        // K₅.
        markPathAlongExternalFace(c.r, c.r)
        markTreePath(Swift.min(c.ux, c.uy, c.uz), c.r)
        markTreePathsToDescendants()
        markUnembeddedEdges()
    }
}
