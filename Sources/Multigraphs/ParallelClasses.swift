import AdjacencyListModule

@frozen
@usableFromInline
internal struct _ParallelLinks {
    @usableFromInline var previous: Int
    @usableFromInline var next: Int

    @inlinable
    init(previous: Int, next: Int) {
        self.previous = previous
        self.next = next
    }
}

/// A class of two or more copies: oldest, newest, count. While on the free list, `count` holds
/// the next free index (or -1) and `first` is -1.
@frozen
@usableFromInline
internal struct _ParallelClass {
    @usableFromInline var first: Int
    @usableFromInline var last: Int
    @usableFromInline var count: Int

    @inlinable
    init(first: Int, last: Int, count: Int) {
        self.first = first
        self.last = last
        self.count = count
    }
}

extension _ParallelLinks: Sendable {}
extension _ParallelClass: Sendable {}

/// The copies of every pair, by pair: the map's value is one Int, as in the simple lists. A value
/// v ≥ 0 is a lone copy at position v; v < 0 is the class of two or more copies at `multi[~v]`,
/// whose copies are linked oldest to newest through `links` (one entry per position).
@frozen
@usableFromInline
internal struct _ParallelClasses {
    @usableFromInline var links: ContiguousArray<_ParallelLinks>
    @usableFromInline var classes: _SlotPairTable<Int>
    @usableFromInline var multi: ContiguousArray<_ParallelClass>
    @usableFromInline var freeMulti: Int

    @inlinable
    init() {
        links = []
        classes = _SlotPairTable()
        multi = []
        freeMulti = -1
    }

    @inlinable
    subscript(key: _SlotPair) -> Int? { classes[key] }

    @inlinable
    func count(ofValue value: Int) -> Int { value >= 0 ? 1 : multi[~value].count }

    @inlinable
    func last(at index: Int) -> Int {
        let value = classes.value(at: index)
        return value >= 0 ? value : multi[~value].last
    }

    @inlinable
    mutating func _allocate(_ parallel: _ParallelClass) -> Int {
        if freeMulti >= 0 {
            let c = freeMulti
            freeMulti = multi[c].count
            multi[c] = parallel
            return c
        }
        multi.append(parallel)
        return multi.count - 1
    }

    @inlinable
    mutating func append(_ position: Int, key: _SlotPair) {
        links.append(_ParallelLinks(previous: -1, next: -1))
        let (inserted, index) = classes.insert(key, position)
        if inserted { return }
        var value = classes.value(at: index)
        Self._append(position, to: &value, links: &links, multi: &multi, freeMulti: &freeMulti)
        classes.setValue(value, at: index)
    }

    @inlinable
    static func _append(
        _ position: Int, to value: inout Int, links: inout ContiguousArray<_ParallelLinks>,
        multi: inout ContiguousArray<_ParallelClass>, freeMulti: inout Int
    ) {
        if value >= 0 {
            links[value] = _ParallelLinks(previous: -1, next: position)
            links[position].previous = value
            let parallel = _ParallelClass(first: value, last: position, count: 2)
            if freeMulti >= 0 {
                let c = freeMulti
                freeMulti = multi[c].count
                multi[c] = parallel
                value = ~c
            } else {
                multi.append(parallel)
                value = ~(multi.count - 1)
            }
        } else {
            let c = ~value
            let previous = multi[c].last
            links[previous].next = position
            links[position].previous = previous
            multi[c].last = position
            multi[c].count += 1
        }
    }

    @inlinable
    mutating func unlink(_ position: Int, key: _SlotPair) {
        guard let index = classes.index(forKey: key) else { preconditionFailure("Edge missing from its parallel class") }
        unlink(position, at: index)
    }

    @inlinable
    mutating func unlink(_ position: Int, at index: Int) {
        let value = classes.value(at: index)
        if value >= 0 {
            classes.remove(at: index)
            return
        }
        let c = ~value
        let link = links[position]
        if link.previous != -1 { links[link.previous].next = link.next } else { multi[c].first = link.next }
        if link.next != -1 { links[link.next].previous = link.previous } else { multi[c].last = link.previous }
        multi[c].count -= 1
        if multi[c].count == 1 {
            classes.setValue(multi[c].first, at: index)
            multi[c] = _ParallelClass(first: -1, last: -1, count: freeMulti)
            freeMulti = c
        }
    }

    @inlinable
    mutating func move(from source: Int, to target: Int, key: _SlotPair) {
        guard let index = classes.index(forKey: key) else { preconditionFailure("Edge missing from its parallel class") }
        let v = classes.value(at: index)
        if v >= 0 {
            classes.setValue(target, at: index)
            return
        }
        let c = ~v
        let link = links[source]
        links[target] = link
        if link.previous != -1 { links[link.previous].next = target } else { multi[c].first = target }
        if link.next != -1 { links[link.next].previous = target } else { multi[c].last = target }
    }

    @inlinable
    mutating func removeLast() {
        links.removeLast()
    }

    @inlinable
    mutating func rename(_ old: _SlotPair, to new: _SlotPair) {
        if let moved = classes.removeValue(forKey: old) { classes.insert(new, moved) }
    }

    @inlinable
    mutating func removeAll(keepingCapacity: Bool) {
        links.removeAll(keepingCapacity: keepingCapacity)
        classes.removeAll(keepingCapacity: keepingCapacity)
        multi.removeAll(keepingCapacity: keepingCapacity)
        freeMulti = -1
    }

    @inlinable
    mutating func reserveCapacity(_ edgeCount: Int) {
        links.reserveCapacity(edgeCount)
        classes.reserveCapacity(edgeCount)
    }

    @inlinable
    func span(_ key: _SlotPair) -> (first: Int, last: Int, count: Int) {
        guard let value = classes[key] else { return (-1, -1, 0) }
        if value >= 0 { return (value, value, 1) }
        let parallel = multi[~value]
        return (parallel.first, parallel.last, parallel.count)
    }

    @inlinable
    func count(_ key: _SlotPair) -> Int {
        guard let value = classes[key] else { return 0 }
        return count(ofValue: value)
    }
}

extension _ParallelClasses {
    /// The positions of every class of two or more copies whose order (oldest first) is not
    /// increasing position, each as its count followed by its positions oldest first, classes by
    /// their least position: what decoding needs to restore the order.
    @inlinable
    func outOfOrderClasses() -> [Int] {
        var groups: [[Int]] = []
        for (_, value) in classes where value < 0 {
            let parallel = multi[~value]
            var order: [Int] = []
            order.reserveCapacity(parallel.count)
            var p = parallel.first
            for _ in 0 ..< parallel.count {
                order.append(p)
                p = links[p].next
            }
            if zip(order, order.dropFirst()).contains(where: { $0 >= $1 }) { groups.append(order) }
        }
        groups.sort { $0.min()! < $1.min()! }
        return groups.flatMap { [$0.count] + $0 }
    }

    /// Relinks `key`'s class in `order` (oldest first); false unless `order` is exactly the class's
    /// positions.
    @inlinable
    mutating func reorder(_ key: _SlotPair, _ order: [Int]) -> Bool {
        guard let value = classes[key], value < 0 else { return false }
        let c = ~value
        guard multi[c].count == order.count else { return false }
        var members = Set<Int>()
        var p = multi[c].first
        for _ in 0 ..< multi[c].count {
            members.insert(p)
            p = links[p].next
        }
        guard Set(order) == members, members.count == order.count else { return false }
        for (k, q) in order.enumerated() {
            links[q] = _ParallelLinks(previous: k == 0 ? -1 : order[k - 1], next: k + 1 == order.count ? -1 : order[k + 1])
        }
        multi[c].first = order[0]
        multi[c].last = order[order.count - 1]
        return true
    }
}

extension _ParallelClasses: Sendable {}
