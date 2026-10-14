/// Boykov–Kolmogorov (2004): a search tree grown from the source over arcs with residual and one
/// grown from the sink over arcs into it, both kept between augmentations. Growth stops when the
/// trees touch; the path through the touching arc is augmented by its bottleneck; the vertices
/// whose tree arc saturated become orphans, and each is re-adopted by a neighbor in its tree that
/// still reaches the tree's terminal, the one closest to it (the timestamp and distance marks of
/// the paper), or else freed, its children orphaned and its tree neighbors made active. Ends when
/// no vertex is active. O(n² m |f|) with integer capacities.
@inlinable
func _boykovKolmogorov<C: Comparable & AdditiveArithmetic>(_ network: _ResidualNetwork<C>, from source: Int, to sink: Int) -> C {
    let n = network.count
    let first = network.first, head = network.head, mate = network.mate, residual = network.residual
    // tree: 0 free, 1 the source's, 2 the sink's. parent: the arc from the vertex to its parent
    // (for the source's tree, the reverse of the arc the flow takes), or one of the markers.
    let free: UInt8 = 0, sourceTree: UInt8 = 1, sinkTree: UInt8 = 2
    let none = -3, terminal = -2, orphan = -1
    let tree = UnsafeMutablePointer<UInt8>.allocate(capacity: max(n, 1))
    let parent = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    let stamp = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    let distance = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    // The active vertices as a linked queue: next[v] is −1 when v is not queued, v when it is last.
    let next = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    let orphans = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    // Each active vertex's scan position in its row: arcs before it lead into its own tree.
    let scan = UnsafeMutablePointer<Int>.allocate(capacity: max(n, 1))
    // The queue's first and last vertices, −1 when empty; in memory, so that `activate` captures
    // only constants.
    let ends = UnsafeMutablePointer<Int>.allocate(capacity: 2)
    defer {
        ends.deallocate()
        scan.deallocate()
        tree.deallocate()
        parent.deallocate()
        stamp.deallocate()
        distance.deallocate()
        next.deallocate()
        orphans.deallocate()
    }
    tree.initialize(repeating: free, count: n)
    parent.initialize(repeating: none, count: n)
    stamp.initialize(repeating: 0, count: n)
    distance.initialize(repeating: 0, count: n)
    next.initialize(repeating: -1, count: n)
    scan.initialize(repeating: 0, count: n)
    ends[0] = -1
    ends[1] = -1
    @inline(__always) func activate(_ v: Int) {
        scan[v] = first[v]
        guard next[v] < 0 else { return }
        if ends[1] < 0 { ends[0] = v } else { next[ends[1]] = v }
        next[v] = v
        ends[1] = v
    }
    tree[source] = sourceTree
    tree[sink] = sinkTree
    parent[source] = terminal
    parent[sink] = terminal
    distance[source] = 1
    distance[sink] = 1
    activate(source)
    activate(sink)
    var value = C.zero
    var time = 0
    var current = -1
    while true {
        // Growth: from the current vertex, then from each active one, until the trees touch.
        var p = current
        if p >= 0 && tree[p] == free { p = -1 }
        var connect = -1
        while connect < 0 {
            if p < 0 {
                while ends[0] >= 0 {
                    let v = ends[0]
                    ends[0] = next[v] == v ? -1 : next[v]
                    if ends[0] < 0 { ends[1] = -1 }
                    next[v] = -1
                    if tree[v] != free {
                        p = v
                        break
                    }
                }
                if p < 0 { break }
            }
            let side = tree[p]
            var a = scan[p]
            let end = first[p + 1]
            if side == sourceTree {
                while a < end {
                    if residual[a] > .zero {
                        let q = Int(head[a])
                        let t = tree[q]
                        if t == free {
                            tree[q] = sourceTree
                            parent[q] = Int(mate[a])
                            stamp[q] = stamp[p]
                            distance[q] = distance[p] &+ 1
                            activate(q)
                        } else if t == sinkTree {
                            connect = a
                            break
                        }
                    }
                    a &+= 1
                }
            } else {
                while a < end {
                    let back = Int(mate[a])
                    if residual[back] > .zero {
                        let q = Int(head[a])
                        let t = tree[q]
                        if t == free {
                            tree[q] = sinkTree
                            parent[q] = back
                            stamp[q] = stamp[p]
                            distance[q] = distance[p] &+ 1
                            activate(q)
                        } else if t == sourceTree {
                            connect = back
                            break
                        }
                    }
                    a &+= 1
                }
            }
            // Resume at the touching arc next time; a finished row stays finished until the
            // vertex is activated again.
            scan[p] = a
            if connect < 0 { p = -1 }
        }
        if connect < 0 { break }
        current = p
        time &+= 1

        // Augmentation along source … tail(connect) → head(connect) … sink.
        let tailOfConnect = Int(head[Int(mate[connect])]), headOfConnect = Int(head[connect])
        var delta = residual[connect]
        var v = tailOfConnect
        while parent[v] != terminal {
            let up = parent[v]
            let r = residual[Int(mate[up])]
            if r < delta { delta = r }
            v = Int(head[up])
        }
        v = headOfConnect
        while parent[v] != terminal {
            let up = parent[v]
            let r = residual[up]
            if r < delta { delta = r }
            v = Int(head[up])
        }
        residual[connect] -= delta
        residual[Int(mate[connect])] += delta
        var orphanCount = 0
        v = tailOfConnect
        while parent[v] != terminal {
            let up = parent[v], along = Int(mate[up])
            residual[along] -= delta
            residual[up] += delta
            let above = Int(head[up])
            if residual[along] == .zero {
                parent[v] = orphan
                orphans[orphanCount] = v
                orphanCount &+= 1
            }
            v = above
        }
        v = headOfConnect
        while parent[v] != terminal {
            let up = parent[v]
            residual[up] -= delta
            residual[Int(mate[up])] += delta
            let above = Int(head[up])
            if residual[up] == .zero {
                parent[v] = orphan
                orphans[orphanCount] = v
                orphanCount &+= 1
            }
            v = above
        }
        value += delta

        // Adoption.
        while orphanCount > 0 {
            orphanCount &-= 1
            let o = orphans[orphanCount]
            let side = tree[o]
            var best = -1, bestDistance = Int.max
            var a = first[o]
            let end = first[o + 1]
            while a < end {
                let q = Int(head[a])
                // The arc from the candidate parent q toward o (source tree) or from o to q.
                let open = side == sourceTree ? residual[Int(mate[a])] > .zero : residual[a] > .zero
                if open && tree[q] == side && parent[q] != none {
                    var d = 0
                    var j = q
                    while true {
                        if stamp[j] == time {
                            d &+= distance[j]
                            break
                        }
                        let up = parent[j]
                        d &+= 1
                        if up == terminal {
                            stamp[j] = time
                            distance[j] = 1
                            break
                        }
                        if up == orphan {
                            d = Int.max
                            break
                        }
                        j = Int(head[up])
                    }
                    if d < Int.max {
                        if d < bestDistance {
                            best = a
                            bestDistance = d
                        }
                        j = q
                        while stamp[j] != time {
                            stamp[j] = time
                            distance[j] = d
                            d &-= 1
                            j = Int(head[parent[j]])
                        }
                    }
                }
                a &+= 1
            }
            if best >= 0 {
                parent[o] = best
                stamp[o] = time
                distance[o] = bestDistance &+ 1
                continue
            }
            a = first[o]
            while a < end {
                let q = Int(head[a])
                if tree[q] == side {
                    let open = side == sourceTree ? residual[Int(mate[a])] > .zero : residual[a] > .zero
                    if open { activate(q) }
                    let up = parent[q]
                    if up >= 0 && Int(head[up]) == o {
                        parent[q] = orphan
                        orphans[orphanCount] = q
                        orphanCount &+= 1
                    }
                }
                a &+= 1
            }
            tree[o] = free
            parent[o] = none
        }
    }
    return value
}
