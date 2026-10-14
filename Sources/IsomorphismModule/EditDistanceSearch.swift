import GraphProtocols

/// One graph of an edit-distance problem in index space: vertices `0..<count`, edges by ordinal
/// (their offset in `edges`), the edges between each ordered pair of vertices, and each vertex's
/// non-loop edges.
@usableFromInline
struct _EditGraph {
    @usableFromInline let count: Int
    @usableFromInline let edgeCount: Int
    @usableFromInline let isDirected: Bool
    /// Per edge ordinal `e`: its ends at `2e` and `2e + 1` (source, then target, when directed).
    @usableFromInline let ends: [Int]
    /// Cell `a · count + b`: the edges from `a` to `b` (undirected: between them, listed in both
    /// cells; a self-loop once), ascending, as `cellEdges[cellOffsets[c] ..< cellOffsets[c + 1]]`.
    @usableFromInline let cellOffsets: [Int]
    @usableFromInline let cellEdges: [Int]
    /// Per vertex: its non-loop edges, the vertex across each, and whether the edge leaves it
    /// (always true when undirected).
    @usableFromInline let incidenceOffsets: [Int]
    @usableFromInline let incidentEdges: [Int]
    @usableFromInline let incidentEnds: [Int]
    @usableFromInline let incidentLeaves: [Bool]
    /// Per vertex: its number of non-loop edge ends (undirected) or arcs (directed).
    @usableFromInline let degree: [Int]

    @inlinable
    init(count n: Int, isDirected: Bool, ends: [Int]) {
        let m = ends.count / 2
        count = n
        edgeCount = m
        self.isDirected = isDirected
        self.ends = ends
        var cellOffsets = [Int](repeating: 0, count: n * n + 1)
        var incidenceOffsets = [Int](repeating: 0, count: n + 1)
        for e in 0 ..< m {
            let s = ends[2 * e], t = ends[2 * e + 1]
            cellOffsets[s * n + t + 1] += 1
            if s != t {
                if !isDirected { cellOffsets[t * n + s + 1] += 1 }
                incidenceOffsets[s + 1] += 1
                incidenceOffsets[t + 1] += 1
            }
        }
        for c in 0 ..< n * n { cellOffsets[c + 1] += cellOffsets[c] }
        for v in 0 ..< n { incidenceOffsets[v + 1] += incidenceOffsets[v] }
        var cellFill = cellOffsets, incidenceFill = incidenceOffsets
        var cellEdges = [Int](repeating: 0, count: cellOffsets[n * n])
        let ends2 = incidenceOffsets[n]
        var incidentEdges = [Int](repeating: 0, count: ends2)
        var incidentEnds = [Int](repeating: 0, count: ends2)
        var incidentLeaves = [Bool](repeating: true, count: ends2)
        for e in 0 ..< m {
            let s = ends[2 * e], t = ends[2 * e + 1]
            cellEdges[cellFill[s * n + t]] = e
            cellFill[s * n + t] += 1
            if s != t {
                if !isDirected {
                    cellEdges[cellFill[t * n + s]] = e
                    cellFill[t * n + s] += 1
                }
                incidentEdges[incidenceFill[s]] = e
                incidentEnds[incidenceFill[s]] = t
                incidenceFill[s] += 1
                incidentEdges[incidenceFill[t]] = e
                incidentEnds[incidenceFill[t]] = s
                incidentLeaves[incidenceFill[t]] = !isDirected
                incidenceFill[t] += 1
            }
        }
        self.cellOffsets = cellOffsets
        self.cellEdges = cellEdges
        self.incidenceOffsets = incidenceOffsets
        self.incidentEdges = incidentEdges
        self.incidentEnds = incidentEnds
        self.incidentLeaves = incidentLeaves
        degree = (0 ..< n).map { incidenceOffsets[$0 + 1] - incidenceOffsets[$0] }
    }

    /// The edges from `a` to `b` (between them, undirected), as a range of `cellEdges`.
    @inlinable @inline(__always)
    func cell(_ a: Int, _ b: Int) -> Range<Int> {
        let c = a &* count &+ b
        return cellOffsets[c] ..< cellOffsets[c &+ 1]
    }
}

/// The linear sum assignment problem with edit operations (LSAPE): `k1` rows and `k2` columns,
/// each row assigned to a distinct column or deleted, each column left over inserted, at the least
/// total cost. Solved as the square assignment problem on `k1 + k2` rows and columns (Riesen and
/// Bunke's extension: row `i`'s deletion is column `k2 + i`, column `j`'s insertion row `k1 + j`,
/// the remaining cells forbidden or zero) by the Hungarian method with potentials, O((k1 + k2)³).
/// The buffers are kept between calls.
@usableFromInline
struct _EditAssignment<C: SignedNumeric & Comparable> {
    /// `substitution[i · k2 + j]`, `deletion[i]`, `insertion[j]`, filled by the caller.
    @usableFromInline var substitution: [C] = []
    @usableFromInline var deletion: [C] = []
    @usableFromInline var insertion: [C] = []
    /// After `solve`: each row's column, or −1 when the row is deleted.
    @usableFromInline var rowMate: [Int] = []
    @usableFromInline var rowPotential: [C] = []
    @usableFromInline var columnPotential: [C] = []
    @usableFromInline var slack: [C] = []
    @usableFromInline var hasSlack: [Bool] = []
    @usableFromInline var used: [Bool] = []
    @usableFromInline var columnRow: [Int] = []
    @usableFromInline var way: [Int] = []

    @inlinable
    init() {}

    /// Sizes the input buffers for `k1` rows and `k2` columns (contents unspecified).
    @inlinable
    mutating func reserve(_ k1: Int, _ k2: Int) {
        if substitution.count < k1 * k2 { substitution = [C](repeating: .zero, count: k1 * k2) }
        if deletion.count < k1 { deletion = [C](repeating: .zero, count: k1) }
        if insertion.count < k2 { insertion = [C](repeating: .zero, count: k2) }
    }

    /// The cost of cell (`i`, `j`) of the square problem, or nil when it is forbidden.
    @inlinable @inline(__always)
    func cost(_ i: Int, _ j: Int, _ k1: Int, _ k2: Int) -> C? {
        if i < k1 {
            if j < k2 { return substitution[i &* k2 &+ j] }
            return j &- k2 == i ? deletion[i] : nil
        }
        if j < k2 { return i &- k1 == j ? insertion[j] : nil }
        return .zero
    }

    /// The least total cost; `rowMate` holds the assignment.
    @inlinable
    mutating func solve(_ k1: Int, _ k2: Int) -> C {
        let size = k1 + k2
        if rowMate.count < k1 { rowMate = [Int](repeating: -1, count: k1) }
        if size == 0 { return .zero }
        if rowPotential.count < size + 1 {
            rowPotential = [C](repeating: .zero, count: size + 1)
            columnPotential = rowPotential
            slack = rowPotential
            hasSlack = [Bool](repeating: false, count: size + 1)
            used = hasSlack
            columnRow = [Int](repeating: 0, count: size + 1)
            way = columnRow
        }
        for j in 0 ... size {
            rowPotential[j] = .zero
            columnPotential[j] = .zero
            columnRow[j] = 0
        }
        // Rows and columns are 1-based here; column 0 holds the row being added.
        for i in 1 ... size {
            columnRow[0] = i
            var j0 = 0
            for j in 0 ... size {
                hasSlack[j] = false
                used[j] = false
            }
            repeat {
                used[j0] = true
                let i0 = columnRow[j0]
                var delta = C.zero, hasDelta = false, j1 = 0
                for j in 1 ... size where !used[j] {
                    if let c = cost(i0 - 1, j - 1, k1, k2) {
                        let reduced = c - rowPotential[i0] - columnPotential[j]
                        if !hasSlack[j] || reduced < slack[j] {
                            slack[j] = reduced
                            hasSlack[j] = true
                            way[j] = j0
                        }
                    }
                    if hasSlack[j] && (!hasDelta || slack[j] < delta) {
                        delta = slack[j]
                        hasDelta = true
                        j1 = j
                    }
                }
                // The deletion and insertion cells make every partial assignment extendable.
                precondition(hasDelta, "Edit assignment: no augmenting column")
                for j in 0 ... size {
                    if used[j] {
                        rowPotential[columnRow[j]] += delta
                        columnPotential[j] -= delta
                    } else if hasSlack[j] {
                        slack[j] -= delta
                    }
                }
                j0 = j1
            } while columnRow[j0] != 0
            repeat {
                let j1 = way[j0]
                columnRow[j0] = columnRow[j1]
                j0 = j1
            } while j0 != 0
        }
        var total = C.zero
        for j in 1 ... size {
            let i = columnRow[j] - 1
            total += cost(i, j - 1, k1, k2)!
            if i < k1 { rowMate[i] = j - 1 < k2 ? j - 1 : -1 }
        }
        return total
    }
}

/// Traps on a negative, NaN or infinite edit cost.
@inlinable @inline(__always)
func _checkEditCost<C: SignedNumeric & Comparable>(_ c: C) {
    // c − c is zero for every finite value and NaN for NaN and ±∞.
    if !(c >= .zero && c - c == .zero) { preconditionFailure("An edit cost is negative, NaN or infinite") }
}

/// The exact graph edit distance by depth-first branch and bound (Abu-Aisheh, Raveaux, Ramel and
/// Martineau, "An exact graph edit distance algorithm for solving pattern recognition problems",
/// ICPRAM 2015).
///
/// The first graph's vertices are decided one at a time, by decreasing degree: each is
/// substituted by a free vertex of the second graph or deleted; the second graph's vertices left
/// free at the end are inserted. A decision costs its vertex operation plus the exact cost of the
/// edges it settles: the self-loops at the vertex and the edges to every decided vertex, each
/// group of edges between two vertex pairs matched by an edit assignment. The search starts from
/// the bipartite upper bound (Riesen and Bunke 2009: the assignment of the root's lower bound,
/// completed to an edit path), visits children by increasing lower bound and prunes a node whose
/// lower bound reaches the best cost found.
///
/// The lower bound is an edit assignment of the undecided vertices: each pair's cost is its vertex
/// operation, the exact cost of its edges to decided vertices, and half a lower bound on matching
/// its edges to undecided vertices (the branch bound of Blumenthal and Gamper 2018, here with the
/// count bound for the branches: at least |deg − deg′| edges are deleted or inserted). Costs are
/// kept doubled so the halves stay exact.
@usableFromInline
struct _EditDistanceSearch<C: SignedNumeric & Comparable> {
    @usableFromInline let g1: _EditGraph
    @usableFromInline let g2: _EditGraph
    @usableFromInline let vertexSubstitution: [C]
    @usableFromInline let vertexDeletion: [C]
    @usableFromInline let vertexInsertion: [C]
    @usableFromInline let edgeSubstitution: [C]
    @usableFromInline let edgeDeletion: [C]
    @usableFromInline let edgeInsertion: [C]
    /// Per vertex: the least deletion (first graph) or insertion (second) cost of its non-loop
    /// edges; zero without any.
    @usableFromInline var leastDeletion: [C]
    @usableFromInline var leastInsertion: [C]
    /// The first graph's vertices in decision order, and each one's place in it.
    @usableFromInline var order: [Int]
    @usableFromInline var rank: [Int]
    /// The decisions so far: per first-graph vertex its image (−1 deleted, −2 undecided), per
    /// second-graph vertex its preimage (−1 free).
    @usableFromInline var image: [Int]
    @usableFromInline var preimage: [Int]
    @usableFromInline var depth = 0
    @usableFromInline var bestImage: [Int] = []
    /// Doubled.
    @usableFromInline var bestCost: C?
    @usableFromInline let bound: C?
    @usableFromInline let expansionLimit: Int?
    @usableFromInline var expansions = 0
    @usableFromInline var exhausted = false
    @usableFromInline var outer = _EditAssignment<C>()
    @usableFromInline var inner = _EditAssignment<C>()
    /// Scratch for the lower bound: undecided first-graph vertices, free second-graph vertices,
    /// and per vertex its branch: edges (out, in) to undecided vertices and their summed cost.
    @usableFromInline var rows: [Int] = []
    @usableFromInline var columns: [Int] = []
    @usableFromInline var out1: [Int]
    @usableFromInline var in1: [Int]
    @usableFromInline var branchCost1: [C]
    @usableFromInline var out2: [Int]
    @usableFromInline var in2: [Int]
    @usableFromInline var branchCost2: [C]
    /// Per depth, the children's (lower bound, image, cost), in `childStart[d] ..< childStart[d] +
    /// childCount[d]` of the flat buffers.
    @usableFromInline var childBound: [C]
    @usableFromInline var childImage: [Int]
    @usableFromInline var childCost: [C]

    @inlinable
    init(_ g1: _EditGraph, _ g2: _EditGraph, vertexSubstitution: [C], vertexDeletion: [C], vertexInsertion: [C],
         edgeSubstitution: [C], edgeDeletion: [C], edgeInsertion: [C], bound: C?, expansionLimit: Int?) {
        self.g1 = g1
        self.g2 = g2
        self.vertexSubstitution = vertexSubstitution
        self.vertexDeletion = vertexDeletion
        self.vertexInsertion = vertexInsertion
        self.edgeSubstitution = edgeSubstitution
        self.edgeDeletion = edgeDeletion
        self.edgeInsertion = edgeInsertion
        self.bound = bound.map { $0 + $0 }
        self.expansionLimit = expansionLimit
        let n1 = g1.count, n2 = g2.count
        leastDeletion = [C](repeating: .zero, count: n1)
        for v in 0 ..< n1 {
            var least: C?
            for k in g1.incidenceOffsets[v] ..< g1.incidenceOffsets[v + 1] {
                let c = edgeDeletion[g1.incidentEdges[k]]
                if least == nil || c < least! { least = c }
            }
            leastDeletion[v] = least ?? .zero
        }
        leastInsertion = [C](repeating: .zero, count: n2)
        for v in 0 ..< n2 {
            var least: C?
            for k in g2.incidenceOffsets[v] ..< g2.incidenceOffsets[v + 1] {
                let c = edgeInsertion[g2.incidentEdges[k]]
                if least == nil || c < least! { least = c }
            }
            leastInsertion[v] = least ?? .zero
        }
        order = (0 ..< n1).sorted { g1.degree[$0] > g1.degree[$1] || (g1.degree[$0] == g1.degree[$1] && $0 < $1) }
        rank = [Int](repeating: 0, count: n1)
        for (k, v) in order.enumerated() { rank[v] = k }
        image = [Int](repeating: -2, count: n1)
        preimage = [Int](repeating: -1, count: n2)
        out1 = [Int](repeating: 0, count: n1)
        in1 = out1
        branchCost1 = [C](repeating: .zero, count: n1)
        out2 = [Int](repeating: 0, count: n2)
        in2 = out2
        branchCost2 = [C](repeating: .zero, count: n2)
        childBound = [C](repeating: .zero, count: n1 * (n2 + 1))
        childImage = [Int](repeating: 0, count: n1 * (n2 + 1))
        childCost = childBound
        outer.reserve(n1, n2)
    }

    /// The least cost of turning the edges `cellEdges[a]` of the first graph into the edges
    /// `cellEdges[b]` of the second; when `assign` is set, the edge images are written to
    /// `edgeImage`.
    @inlinable
    mutating func groupCost(_ a: Range<Int>, _ b: Range<Int>, assign: Bool = false, _ edgeImage: inout [Int]) -> C {
        let k1 = a.count, k2 = b.count
        if k1 == 0 {
            var c = C.zero
            for k in b { c += edgeInsertion[g2.cellEdges[k]] }
            return c
        }
        if k2 == 0 {
            var c = C.zero
            for k in a { c += edgeDeletion[g1.cellEdges[k]] }
            return c
        }
        if k1 == 1 && k2 == 1 {
            let e = g1.cellEdges[a.lowerBound], f = g2.cellEdges[b.lowerBound]
            let substitute = edgeSubstitution[e * g2.edgeCount + f], replace = edgeDeletion[e] + edgeInsertion[f]
            if assign { edgeImage[e] = substitute <= replace ? f : -1 }
            return substitute <= replace ? substitute : replace
        }
        inner.reserve(k1, k2)
        for (i, ka) in a.enumerated() {
            let e = g1.cellEdges[ka]
            inner.deletion[i] = edgeDeletion[e]
            for (j, kb) in b.enumerated() { inner.substitution[i * k2 + j] = edgeSubstitution[e * g2.edgeCount + g2.cellEdges[kb]] }
        }
        for (j, kb) in b.enumerated() { inner.insertion[j] = edgeInsertion[g2.cellEdges[kb]] }
        let c = inner.solve(k1, k2)
        if assign {
            for (i, ka) in a.enumerated() {
                let j = inner.rowMate[i]
                edgeImage[g1.cellEdges[ka]] = j < 0 ? -1 : g2.cellEdges[b.lowerBound + j]
            }
        }
        return c
    }

    /// The cost of the edges settled by deciding `u` ↦ `x` (−1: deleted) after the first `depth`
    /// decisions: `u`'s self-loops and its edges to every decided vertex. Single units.
    @inlinable
    mutating func settledCost(_ u: Int, _ x: Int) -> C {
        var none: [Int] = []
        let empty = 0 ..< 0
        var c = groupCost(g1.cell(u, u), x >= 0 ? g2.cell(x, x) : empty, &none)
        for k in 0 ..< depth {
            let w = order[k], y = image[w]
            let mapped = y >= 0 && x >= 0
            c += groupCost(g1.cell(u, w), mapped ? g2.cell(x, y) : empty, &none)
            if g1.isDirected { c += groupCost(g1.cell(w, u), mapped ? g2.cell(y, x) : empty, &none) }
        }
        return c
    }

    /// The cost of inserting the edges between the free vertex `v` and the images decided so far,
    /// and `v`'s self-loops. Single units.
    @inlinable
    func insertedCost(_ v: Int) -> C {
        var c = C.zero
        for k in g2.cell(v, v) { c += edgeInsertion[g2.cellEdges[k]] }
        for k in 0 ..< depth {
            let y = image[order[k]]
            guard y >= 0 else { continue }
            for q in g2.cell(v, y) { c += edgeInsertion[g2.cellEdges[q]] }
            if g2.isDirected { for q in g2.cell(y, v) { c += edgeInsertion[g2.cellEdges[q]] } }
        }
        return c
    }

    /// The count bound on matching `a` edges with `b`: the surplus is deleted or inserted.
    @inlinable @inline(__always)
    func surplus(_ a: Int, _ b: Int, _ deletion: C, _ insertion: C) -> C {
        if a > b { return C(exactly: a - b)! * deletion }
        if b > a { return C(exactly: b - a)! * insertion }
        return .zero
    }

    /// A lower bound on the cost of completing the current decisions, doubled; `outer.rowMate`
    /// then holds the assignment of `rows` to `columns`.
    @inlinable
    mutating func lowerBound() -> C {
        let n1 = g1.count, n2 = g2.count
        rows.removeAll(keepingCapacity: true)
        columns.removeAll(keepingCapacity: true)
        for k in depth ..< n1 { rows.append(order[k]) }
        for v in 0 ..< n2 where preimage[v] < 0 { columns.append(v) }
        for u in rows {
            var o = 0, i = 0, c = C.zero
            for k in g1.incidenceOffsets[u] ..< g1.incidenceOffsets[u + 1] where rank[g1.incidentEnds[k]] >= depth {
                if g1.incidentLeaves[k] { o += 1 } else { i += 1 }
                c += edgeDeletion[g1.incidentEdges[k]]
            }
            out1[u] = o
            in1[u] = i
            branchCost1[u] = c
        }
        for v in columns {
            var o = 0, i = 0, c = C.zero
            for k in g2.incidenceOffsets[v] ..< g2.incidenceOffsets[v + 1] where preimage[g2.incidentEnds[k]] < 0 {
                if g2.incidentLeaves[k] { o += 1 } else { i += 1 }
                c += edgeInsertion[g2.incidentEdges[k]]
            }
            out2[v] = o
            in2[v] = i
            branchCost2[v] = c
        }
        let k1 = rows.count, k2 = columns.count
        for i in 0 ..< k1 {
            let u = rows[i]
            for j in 0 ..< k2 {
                let x = columns[j]
                let settled = vertexSubstitution[u * n2 + x] + settledCost(u, x)
                let branch = surplus(out1[u], out2[x], leastDeletion[u], leastInsertion[x])
                    + surplus(in1[u], in2[x], leastDeletion[u], leastInsertion[x])
                outer.substitution[i * k2 + j] = settled + settled + branch
            }
            let settled = vertexDeletion[u] + settledCost(u, -1)
            outer.deletion[i] = settled + settled + branchCost1[u]
        }
        for j in 0 ..< k2 {
            let x = columns[j]
            let settled = vertexInsertion[x] + insertedCost(x)
            outer.insertion[j] = settled + settled + branchCost2[x]
        }
        return outer.solve(k1, k2)
    }

    /// Whether a node with lower bound `lower` (doubled) cannot lead to a better edit path.
    @inlinable @inline(__always)
    func isPruned(_ lower: C) -> Bool {
        if let bestCost { return lower >= bestCost }
        if let bound { return lower > bound }
        return false
    }

    /// The cost of the edit path given by `mapping` (per first-graph vertex its image or −1),
    /// in single units; with `assign`, each first-graph edge's image (−1 deleted) in `edgeImage`.
    @inlinable
    mutating func pathCost(_ mapping: [Int], assign: Bool, _ edgeImage: inout [Int]) -> C {
        let n1 = g1.count, n2 = g2.count
        var c = C.zero
        var used = [Bool](repeating: false, count: n2)
        for u in 0 ..< n1 {
            let x = mapping[u]
            if x >= 0 {
                used[x] = true
                c += vertexSubstitution[u * n2 + x]
            } else {
                c += vertexDeletion[u]
            }
        }
        for v in 0 ..< n2 where !used[v] { c += vertexInsertion[v] }
        let empty = 0 ..< 0
        for a in 0 ..< n1 {
            for b in (g1.isDirected ? 0 : a) ..< n1 {
                let x = mapping[a], y = mapping[b]
                c += groupCost(g1.cell(a, b), x >= 0 && y >= 0 ? g2.cell(x, y) : empty, assign: assign, &edgeImage)
            }
        }
        for f in 0 ..< g2.edgeCount where !used[g2.ends[2 * f]] || !used[g2.ends[2 * f + 1]] { c += edgeInsertion[f] }
        return c
    }

    /// The best edit path found below the current node, whose decisions cost `cost` (doubled).
    @inlinable
    mutating func search(_ cost: C) {
        let n1 = g1.count, n2 = g2.count
        if depth == n1 {
            var total = cost
            for v in 0 ..< n2 where preimage[v] < 0 { total += vertexInsertion[v] + vertexInsertion[v] }
            for f in 0 ..< g2.edgeCount where preimage[g2.ends[2 * f]] < 0 || preimage[g2.ends[2 * f + 1]] < 0 {
                total += edgeInsertion[f] + edgeInsertion[f]
            }
            if !isPruned(total) {
                bestCost = total
                bestImage = image
            }
            return
        }
        if let expansionLimit, expansions >= expansionLimit {
            exhausted = true
            return
        }
        expansions += 1
        let u = order[depth]
        let start = depth * (n2 + 1)
        var count = 0
        for x in -1 ..< n2 where x < 0 || preimage[x] < 0 {
            let step = x >= 0 ? vertexSubstitution[u * n2 + x] + settledCost(u, x) : vertexDeletion[u] + settledCost(u, -1)
            let childCost = cost + step + step
            image[u] = x
            if x >= 0 { preimage[x] = u }
            depth += 1
            let lower = childCost + lowerBound()
            depth -= 1
            image[u] = -2
            if x >= 0 { preimage[x] = -1 }
            if isPruned(lower) { continue }
            // Insertion sort by (lower bound, image), the deletion (−1) last on ties.
            var k = count
            while k > 0 {
                let previous = start + k - 1
                let key = childImage[previous] < 0 ? n2 : childImage[previous], mine = x < 0 ? n2 : x
                if childBound[previous] > lower || (childBound[previous] == lower && key > mine) {
                    childBound[previous + 1] = childBound[previous]
                    childImage[previous + 1] = childImage[previous]
                    self.childCost[previous + 1] = self.childCost[previous]
                    k -= 1
                } else {
                    break
                }
            }
            childBound[start + k] = lower
            childImage[start + k] = x
            self.childCost[start + k] = childCost
            count += 1
        }
        for k in 0 ..< count {
            if isPruned(childBound[start + k]) { break }
            let x = childImage[start + k]
            image[u] = x
            if x >= 0 { preimage[x] = u }
            depth += 1
            search(self.childCost[start + k])
            depth -= 1
            image[u] = -2
            if x >= 0 { preimage[x] = -1 }
            if exhausted { return }
        }
    }

    /// Runs the search: the bipartite upper bound, then branch and bound. The result is the best
    /// path's vertex images and edge images (−1 deleted), its cost and whether it is proven
    /// optimal, or nil when no path costs at most `bound`.
    @inlinable
    mutating func run() -> (vertexImages: [Int], edgeImages: [Int], cost: C, isOptimal: Bool)? {
        let n1 = g1.count
        var none: [Int] = []
        _ = lowerBound()
        var heuristic = [Int](repeating: -1, count: n1)
        for (i, u) in rows.enumerated() { heuristic[u] = outer.rowMate[i] < 0 ? -1 : columns[outer.rowMate[i]] }
        let heuristicCost = pathCost(heuristic, assign: false, &none)
        if !isPruned(heuristicCost + heuristicCost) {
            bestCost = heuristicCost + heuristicCost
            bestImage = heuristic
        }
        search(.zero)
        guard bestCost != nil else { return nil }
        var edgeImages = [Int](repeating: -1, count: g1.edgeCount)
        let cost = pathCost(bestImage, assign: true, &edgeImages)
        return (bestImage, edgeImages, cost, !exhausted)
    }
}
