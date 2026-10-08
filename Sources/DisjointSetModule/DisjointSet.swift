/// A partition of the elements `0..<count` into disjoint sets, with union by size and path
/// halving: O(α(n)) amortized per operation. The interface is that of Boost's `disjoint_sets`,
/// petgraph's `UnionFind` and scipy's `DisjointSet`; the linking rule is scipy's (Boost and
/// petgraph link by rank).
///
/// Each set's representative is one of its members. `union(a, b)` keeps the representative of
/// the larger set, or, for sets of the same size, the smaller of the two representatives, whatever
/// the order of the arguments. Neither `find` nor a union of elements already in one set changes
/// a representative, so representatives depend only on the sequence of unions that merged sets.
///
/// Two disjoint sets are equal when they have the same elements, partitioned the same way. The
/// representative `find` returns is not part of the value: equal disjoint sets can name the same
/// set by different representatives.
///
/// Storage is one array of `count` integers, copied on write. `find` and `union(_:_:)` are
/// `mutating` because they shorten paths; every other query works on a `let`, walking at most
/// ⌊log₂ count⌋ steps (union by size bounds the height).
@frozen
public struct DisjointSet {
    /// For a representative, minus the size of its set; for any other element, its parent.
    @usableFromInline var _storage: [Int]
    @usableFromInline var _setCount: Int

    /// A disjoint set with no elements.
    @inlinable
    public init() {
        _storage = []
        _setCount = 0
    }

    /// The singletons `{0}`, `{1}`, …, `{count − 1}`.
    ///
    /// - Precondition: `count >= 0`.
    @inlinable
    public init(count: Int) {
        precondition(count >= 0, "A disjoint set cannot have a negative count")
        _storage = [Int](repeating: -1, count: count)
        _setCount = count
    }

    /// The number of elements.
    @inlinable
    public var count: Int { _storage.count }

    /// Whether there are no elements.
    @inlinable
    public var isEmpty: Bool { _storage.isEmpty }

    /// The number of sets. O(1).
    @inlinable
    public var setCount: Int { _setCount }

    /// Adds the singleton `{count}` and returns its element, the old `count`.
    @inlinable
    @discardableResult
    public mutating func makeSet() -> Int {
        _storage.append(-1)
        _setCount += 1
        return _storage.count - 1
    }

    /// Reserves room for `minimumCapacity` elements in all.
    ///
    /// - Precondition: `minimumCapacity >= 0`.
    @inlinable
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        precondition(minimumCapacity >= 0, "A capacity cannot be negative")
        _storage.reserveCapacity(minimumCapacity)
    }

    @inlinable
    @inline(__always)
    func _checkElement(_ element: Int) {
        precondition(UInt(bitPattern: element) < UInt(bitPattern: _storage.count), "Element \(element) is out of range 0..<\(_storage.count)")
    }

    @usableFromInline
    @inline(never)
    func _outOfRange(_ element: Int) -> Never {
        preconditionFailure("Element \(element) is out of range 0..<\(_storage.count)")
    }

    /// The representative of `element`'s set, without shortening the path. At most ⌊log₂ count⌋
    /// steps.
    @inlinable
    @inline(__always)
    func _root(_ element: Int) -> Int {
        _storage.withUnsafeBufferPointer { storage in
            var x = element
            while storage[x] >= 0 { x = storage[x] }
            return x
        }
    }

    /// The representative of `element`'s set, pointing each element on the way at its
    /// grandparent. A `find` along a path already flat writes nothing, so it does not copy storage
    /// shared with another value; one that shortens a path copies it once, O(count). To ask
    /// whether two elements are together on a shared or borrowed value, use `inSameSet(_:_:)`,
    /// which never writes.
    ///
    /// The representative is not part of the value: equal disjoint sets can return different
    /// representatives for the same element.
    ///
    /// - Precondition: `element` is in `0..<count`.
    @inlinable
    public mutating func find(_ element: Int) -> Int {
        _checkElement(element)
        let parent = _storage[element]
        if parent < 0 { return element }
        if _storage[parent] < 0 { return parent }
        return _storage.withUnsafeMutableBufferPointer { _halve($0, element) }
    }

    /// Merges the sets containing `a` and `b`. Returns whether they were different sets.
    ///
    /// - Precondition: `a` and `b` are in `0..<count`.
    @inlinable
    @discardableResult
    public mutating func union(_ a: Int, _ b: Int) -> Bool {
        _checkElement(a)
        _checkElement(b)
        // Two elements a step or less from the same representative: nothing to write, so no
        // uniqueness check (the common case late in Kruskal).
        let settled = _storage.withUnsafeBufferPointer { storage in
            let pa = storage[a], pb = storage[b]
            let ra = pa < 0 ? a : storage[pa] < 0 ? pa : -1
            return ra >= 0 && ra == (pb < 0 ? b : storage[pb] < 0 ? pb : -2)
        }
        if settled { return false }
        let merged = _storage.withUnsafeMutableBufferPointer { storage -> Bool in
            let x = _halve(storage, a)
            let y = _halve(storage, b)
            if x == y { return false }
            // The larger set's representative stays; on a tie, the smaller one.
            let sizeX = storage[x], sizeY = storage[y]
            let (root, child) = sizeX < sizeY || (sizeX == sizeY && x < y) ? (x, y) : (y, x)
            storage[root] = sizeX + sizeY
            storage[child] = root
            return true
        }
        if merged { _setCount -= 1 }
        return merged
    }

    /// Whether `a` and `b` are in the same set. Never writes, so it works on a `let` and never
    /// copies shared storage (petgraph's `equiv`).
    ///
    /// - Precondition: `a` and `b` are in `0..<count`.
    @inlinable
    public func inSameSet(_ a: Int, _ b: Int) -> Bool {
        _checkElement(a)
        _checkElement(b)
        return _root(a) == _root(b)
    }

    /// The number of elements in `element`'s set. Never writes.
    ///
    /// - Precondition: `element` is in `0..<count`.
    @inlinable
    public func setSize(of element: Int) -> Int {
        _checkElement(element)
        return -_storage[_root(element)]
    }

    /// For each element, the position of its set in `sets()`: labels run over `0..<setCount`, in
    /// the order of each set's smallest element. O(count). (Not petgraph's `into_labeling`, which
    /// gives representatives.)
    @inlinable
    public func labels() -> [Int] {
        let n = _storage.count
        var labels = [Int](repeating: -1, count: n)
        // Each element's representative, found once: a walk stops at the first element whose
        // representative is known, and then records it along the way.
        var roots = [Int](repeating: -1, count: n)
        labels.withUnsafeMutableBufferPointer { labels in
            roots.withUnsafeMutableBufferPointer { roots in
                _storage.withUnsafeBufferPointer { storage in
                    var next = 0
                    for x in 0 ..< n {
                        var y = x
                        while storage[y] >= 0 && roots[y] < 0 { y = storage[y] }
                        let root = storage[y] < 0 ? y : roots[y]
                        var z = x
                        while z != y {
                            roots[z] = root
                            z = storage[z]
                        }
                        // A representative's slot holds its set's label from the set's first
                        // (smallest) element on.
                        if labels[root] < 0 {
                            labels[root] = next
                            next += 1
                        }
                        labels[x] = labels[root]
                    }
                }
            }
        }
        return labels
    }

    /// The sets, ordered by their smallest element, each listing its elements in ascending order.
    /// O(count).
    @inlinable
    public func sets() -> [[Int]] {
        let labels = labels()
        var sizes = [Int](repeating: 0, count: _setCount)
        for label in labels { sizes[label] += 1 }
        var sets: [[Int]] = []
        sets.reserveCapacity(_setCount)
        for size in sizes {
            var set: [Int] = []
            set.reserveCapacity(size)
            sets.append(set)
        }
        for (x, label) in labels.enumerated() { sets[label].append(x) }
        return sets
    }
}

/// The root of `x`'s set, pointing each element on the way at its grandparent.
@inlinable
@inline(__always)
func _halve(_ storage: UnsafeMutableBufferPointer<Int>, _ x: Int) -> Int {
    var x = x
    while storage[x] >= 0 {
        let p = storage[x]
        let g = storage[p]
        if g < 0 { return p }
        storage[x] = g
        x = g
    }
    return x
}

extension DisjointSet: Hashable {
    /// Whether both have the same elements, partitioned the same way, whatever the
    /// representatives. O(count).
    @inlinable
    public static func == (lhs: DisjointSet, rhs: DisjointSet) -> Bool {
        guard lhs._storage.count == rhs._storage.count, lhs._setCount == rhs._setCount else { return false }
        let identical = lhs._storage.withUnsafeBufferPointer { l in
            rhs._storage.withUnsafeBufferPointer { r in l.baseAddress == r.baseAddress }
        }
        return identical || lhs.labels() == rhs.labels()
    }

    /// Hashes the partition, so equal values hash alike. O(count).
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(labels())
    }
}

extension DisjointSet: Sendable {}

extension DisjointSet: CustomStringConvertible, CustomDebugStringConvertible {
    /// The sets as `sets()` lists them, at most 16 sets of at most 16 elements:
    /// `[[0, 1, 3], [2]]`. Representatives are not shown, so equal values print alike.
    public var description: String {
        let sets = sets()
        var parts = sets.prefix(16).map { set in
            var items = set.prefix(16).map(String.init)
            if set.count > 16 { items.append("…") }
            return "[" + items.joined(separator: ", ") + "]"
        }
        if sets.count > 16 { parts.append("…") }
        return "[" + parts.joined(separator: ", ") + "]"
    }

    /// The type, the counts and the sets.
    public var debugDescription: String {
        "DisjointSet(count: \(count), setCount: \(setCount), sets: \(description))"
    }
}
