extension FunctionalGraph {
    /// Every cycle of a functional graph, and for each vertex its tail and the cycle it reaches, in
    /// Flajolet and Odlyzko's terms: walking from `v`, the first vertex on a cycle is `root(of: v)`,
    /// `tailLength(of: v)` steps away (Sage's "preperiod"), on a cycle of `cycleLength(of: v)`
    /// vertices. For a permutation, `cycles` is its cycle decomposition and every tail is zero.
    ///
    /// Built by `cycleDecomposition()` in O(n); every query is O(1) except
    /// `successor(of:steps:)`, which is O(log n) for any number of steps.
    @frozen
    public struct CycleDecomposition: Sendable {
        /// `_preimageStarts[v] ..< _preimageStarts[v + 1]` is the row of `v` in `_preimages`.
        @usableFromInline let _preimageStarts: [Int]
        /// Every vertex's preimages, row by row, each row ascending.
        @usableFromInline let _preimages: [Int]
        /// Per vertex, together so that a query reads one cache line.
        @usableFromInline let _records: [_Record]
        /// Every vertex, by depth: first the cycles, each from its least vertex in walk order, the
        /// cycles by least vertex; then each depth's vertices in preorder.
        @usableFromInline let _byDepth: [Int]
        /// The preorder number of each tree vertex in `_byDepth`, at the same place, so the
        /// level-ancestor search reads one array (ascending within each depth).
        @usableFromInline let _keysByDepth: [Int32]
        /// `_depthStarts[d] ..< _depthStarts[d + 1]` is the depth-`d` segment of `_byDepth`.
        @usableFromInline let _depthStarts: [Int]
        /// `_cycleStarts[c] ..< _cycleStarts[c + 1]` is cycle `c` in `_byDepth`.
        @usableFromInline let _cycleStarts: [Int]

        /// A vertex's tail length (its depth in its tree, 0 on a cycle); for a tree vertex its root
        /// and its preorder number among all tree vertices (trees in the order of `cycles`); for a
        /// cyclic vertex (its own root) its component and its position in `_byDepth`. Three
        /// `Int32`s, read and written as `Int`s, so a query or a build step touches one 12-byte
        /// record (as `Trees` does with its node records).
        @frozen
        @usableFromInline
        struct _Record: Sendable {
            @usableFromInline var _tail: Int32
            @usableFromInline var _root: Int32
            @usableFromInline var _key: Int32

            @inlinable @inline(__always)
            init(tail: Int, root: Int, key: Int) {
                _tail = Int32(truncatingIfNeeded: tail)
                _root = Int32(truncatingIfNeeded: root)
                _key = Int32(truncatingIfNeeded: key)
            }

            @inlinable var tail: Int { @inline(__always) get { Int(_tail) } }
            @inlinable var root: Int { @inline(__always) get { Int(_root) } }
            @inlinable var key: Int { @inline(__always) get { Int(_key) } }
        }

        @inlinable
        init(_preimageStarts: [Int], _preimages: [Int], _records: [_Record], _byDepth: [Int], _keysByDepth: [Int32], _depthStarts: [Int], _cycleStarts: [Int]) {
            self._keysByDepth = _keysByDepth
            self._preimageStarts = _preimageStarts
            self._preimages = _preimages
            self._records = _records
            self._byDepth = _byDepth
            self._depthStarts = _depthStarts
            self._cycleStarts = _cycleStarts
        }

        /// The cycles as a collection of slices of one array, as `Components` lists components.
        @frozen
        public struct Cycles: RandomAccessCollection, Sendable {
            public typealias Index = Int
            public typealias Element = ArraySlice<Int>
            public typealias Indices = Range<Int>

            @usableFromInline let _vertices: [Int]
            @usableFromInline let _starts: [Int]

            @inlinable
            init(_vertices: [Int], _starts: [Int]) {
                self._vertices = _vertices
                self._starts = _starts
            }

            @inlinable public var startIndex: Int { 0 }
            @inlinable public var endIndex: Int { _starts.count - 1 }
            @inlinable public var indices: Range<Int> { 0 ..< _starts.count - 1 }
            @inlinable public func index(after i: Int) -> Int { i + 1 }
            @inlinable public func index(before i: Int) -> Int { i - 1 }

            /// Cycle `position`, from its least vertex in walk order (v, f(v), …). O(1).
            @inlinable
            public subscript(position: Int) -> ArraySlice<Int> {
                precondition(position >= 0 && position < _starts.count - 1, "Cycle index out of range")
                return _vertices[_starts[position] ..< _starts[position + 1]]
            }
        }

        /// The cycles, each listed from its least vertex in walk order (v, f(v), …), and ordered by
        /// least vertex. O(1).
        @inlinable
        public var cycles: Cycles { Cycles(_vertices: _byDepth, _starts: _cycleStarts) }

        @inlinable
        @inline(__always)
        internal func _check(_ vertex: Int) {
            precondition(UInt(bitPattern: vertex) < UInt(bitPattern: _records.count), "\(vertex) is not a vertex of the graph")
        }

        /// The index in `cycles` of the cycle `vertex` reaches. O(1).
        ///
        /// - Precondition: `vertex` is a vertex of the graph.
        @inlinable
        public func component(of vertex: Int) -> Int {
            _check(vertex)
            let record = _records[vertex]
            return record.tail == 0 ? record.root : _records[record.root].root
        }

        /// The first vertex on a cycle that the walk from `vertex` reaches: the root of its tree
        /// (not the cycle's least vertex). `vertex` itself when it is on a cycle. O(1).
        ///
        /// - Precondition: `vertex` is a vertex of the graph.
        @inlinable
        public func root(of vertex: Int) -> Int {
            _check(vertex)
            let record = _records[vertex]
            return record.tail == 0 ? vertex : record.root
        }

        /// The number of steps from `vertex` to `root(of: vertex)` (Flajolet and Odlyzko's tail
        /// length, Sage's preperiod); 0 on a cycle. O(1).
        ///
        /// - Precondition: `vertex` is a vertex of the graph.
        @inlinable
        public func tailLength(of vertex: Int) -> Int {
            _check(vertex)
            return _records[vertex].tail
        }

        /// The length of the cycle `vertex` reaches. O(1).
        ///
        /// - Precondition: `vertex` is a vertex of the graph.
        @inlinable
        public func cycleLength(of vertex: Int) -> Int {
            let c = component(of: vertex)
            return _cycleStarts[c + 1] - _cycleStarts[c]
        }

        /// The vertices whose successor is `vertex`, ascending. O(1).
        ///
        /// - Precondition: `vertex` is a vertex of the graph.
        @inlinable
        public func preimages(of vertex: Int) -> ArraySlice<Int> {
            _check(vertex)
            return _preimages[_preimageStarts[vertex] ..< _preimageStarts[vertex + 1]]
        }

        /// The number of vertices whose successor is `vertex`. O(1).
        ///
        /// - Precondition: `vertex` is a vertex of the graph.
        @inlinable
        public func inDegree(of vertex: Int) -> Int {
            _check(vertex)
            return _preimageStarts[vertex + 1] - _preimageStarts[vertex]
        }

        /// f^k(v), for any k. O(log n): below the tail length, a binary search for the ancestor at
        /// the right depth (a level-ancestor query); from there, O(1) by position on the cycle.
        ///
        /// - Precondition: `vertex` is a vertex of the graph, and `steps >= 0`.
        @inlinable
        public func successor(of vertex: Int, steps: Int) -> Int {
            _check(vertex)
            precondition(steps >= 0, "negative step count \(steps)")
            let record = _records[vertex]
            let tail = record.tail
            if steps < tail {
                // The ancestor at depth tail − steps (at least 1) is the vertex there with the
                // greatest preorder number not above vertex's: the subtree of each vertex is a
                // contiguous run of preorder numbers.
                let depth = tail - steps
                let key = record._key
                let low = _keysByDepth.withUnsafeBufferPointer { keys in
                    var low = _depthStarts[depth], high = _depthStarts[depth + 1]
                    // Invariant: the answer is in low ..< high.
                    while high &- low > 1 {
                        let middle = low &+ (high &- low) >> 1
                        if keys[middle] <= key { low = middle } else { high = middle }
                    }
                    return low
                }
                return _byDepth[low]
            }
            let root = tail == 0 ? record : _records[record.root]
            let start = _cycleStarts[root.root]
            let length = _cycleStarts[root.root + 1] - start
            // Both terms are below `length`, so the sum cannot overflow.
            let offset = (root.key - start + (steps - tail) % length) % length
            return _byDepth[start + offset]
        }
    }

    /// The cycles of the graph, and every vertex's tail, root and preimages. O(n) time, with no
    /// allocation per vertex. The result holds 5n + 3 `Int`s (two `Int` arrays for the preimage
    /// rows, one for the vertices by depth, a 12-byte record per vertex and a 4-byte preorder
    /// number beside each vertex by depth), plus one per cycle and one per unit of the longest
    /// tail; building it takes 1.5n more for a moment.
    ///
    /// A counting sort of f gives the preimage rows and the in-degrees. Peeling the vertices of
    /// in-degree zero, repeatedly, visits the tree vertices leaves first, summing subtree sizes on
    /// the way, and leaves exactly the cyclic ones; each cycle is then walked from its least
    /// vertex. Revisiting the peeled vertices in reverse, parents first, gives every tail length
    /// and root and a preorder numbering of the trees from the subtree sizes; a counting sort by
    /// depth then lays out the level-ancestor table. Nothing recurses or chases a chain of
    /// dependent reads, so a tail of 10⁷ vertices needs no call stack.
    ///
    /// - Precondition: the graph has fewer than 2³¹ vertices.
    @inlinable
    public func cycleDecomposition() -> CycleDecomposition {
        typealias Record = CycleDecomposition._Record
        let n = _successors.count
        precondition(n < Int(Int32.max), "cycleDecomposition() needs fewer than 2³¹ vertices")
        // Arrays every element of which is written before it is read start uninitialized: fresh
        // pages are much of the cost, and a fill would touch each one twice.
        func uninitialized<T>(_: T.Type, _ count: Int) -> [T] {
            [T](unsafeUninitializedCapacity: count) { _, initialized in initialized = count }
        }
        var preimageStarts = [Int](repeating: 0, count: n + 1)
        var preimages = uninitialized(Int.self, n)
        var records = uninitialized(Record.self, n)
        var byDepth = uninitialized(Int.self, n)
        // The depth-0 part is never read. Until step 5 fills it, this is the peeling queue.
        var keysByDepth = uninitialized(Int32.self, n)
        var depthStarts: [Int] = [0]
        var cycleStarts: [Int] = [0]
        // Scratch: the in-degrees still to peel, then the depths by preorder number; subtree
        // sizes, then the next free preorder number below each vertex; the tree vertices by
        // preorder number.
        var remaining = uninitialized(Int32.self, n)
        var scratch = uninitialized(Int32.self, n)
        var inPreorder = uninitialized(Int32.self, n)
        _successors.withUnsafeBufferPointer { f in
            preimageStarts.withUnsafeMutableBufferPointer { starts in
            preimages.withUnsafeMutableBufferPointer { rows in
            records.withUnsafeMutableBufferPointer { records in
            byDepth.withUnsafeMutableBufferPointer { byDepth in
            keysByDepth.withUnsafeMutableBufferPointer { keysByDepth in
            remaining.withUnsafeMutableBufferPointer { remaining in
            scratch.withUnsafeMutableBufferPointer { scratch in
            inPreorder.withUnsafeMutableBufferPointer { inPreorder in
                // 1. In-degrees, and the leaves into the queue. Then the preimage rows: inclusive
                //    prefix sums (the end of each row), and each source placed from the end of its
                //    row, sources descending, so every row is ascending and `starts[w]` ends at the
                //    start of row w.
                let queue = keysByDepth
                for v in 0 ..< n { starts[f[v]] &+= 1 }
                var end = 0
                for w in 0 ..< n {
                    let degree = starts[w]
                    remaining[w] = Int32(truncatingIfNeeded: degree)
                    scratch[w] = 1
                    if degree == 0 {
                        queue[end] = Int32(truncatingIfNeeded: w)
                        end &+= 1
                    }
                }
                for w in 1 ..< max(n, 1) { starts[w] &+= starts[w &- 1] }
                starts[n] = n
                var v = n &- 1
                while v >= 0 {
                    let w = f[v]
                    starts[w] &-= 1
                    rows[starts[w]] = v
                    v &-= 1
                }

                // 2. Peel, leaves first; a vertex leaves the queue after all its preimages, so its
                //    subtree size is complete when it is added to its successor's.
                var head = 0
                while head < end {
                    let u = Int(queue[head])
                    head &+= 1
                    let w = f[u]
                    scratch[w] &+= scratch[u]
                    let left = remaining[w] &- 1
                    remaining[w] = left
                    if left == 0 {
                        queue[end] = Int32(truncatingIfNeeded: w)
                        end &+= 1
                    }
                }

                // 3. The cycles (what peeling left), each from its least vertex, in order of least
                //    vertex. Each root's trees get the next run of preorder numbers.
                var placed = 0
                var base: Int32 = 0
                for w in 0 ..< n where remaining[w] > 0 {
                    let component = cycleStarts.count &- 1
                    var x = w
                    repeat {
                        records[x] = Record(tail: 0, root: component, key: placed)
                        remaining[x] = 0
                        byDepth[placed] = x
                        placed &+= 1
                        let size = scratch[x]
                        scratch[x] = base
                        base &+= size &- 1
                        x = f[x]
                    } while x != w
                    cycleStarts.append(placed)
                }
                let cyclic = placed
                depthStarts.append(cyclic)

                // 4. Parents first (the peeling order reversed): depth, root and preorder number.
                //    `scratch` holds each numbered vertex's next free number for its children. The
                //    tree vertices go to `inPreorder` and their depths to `remaining`, both by
                //    preorder number, and each depth is counted. (A breadth-first search from the
                //    cycles, which lays each depth out in preorder directly, took twice as long on
                //    a random mapping: it reads each parent's row and record at random.)
                var i = end
                while i > 0 {
                    i &-= 1
                    let u = Int(queue[i])
                    let p = f[u]
                    let parent = records[p]
                    let number = scratch[p]
                    scratch[p] = number &+ scratch[u]
                    scratch[u] = number &+ 1
                    let depth = parent.tail &+ 1
                    records[u] = Record(tail: depth, root: parent.tail == 0 ? p : parent.root, key: Int(number))
                    inPreorder[Int(number)] = Int32(truncatingIfNeeded: u)
                    remaining[Int(number)] = Int32(truncatingIfNeeded: depth)
                    if depth &+ 1 == depthStarts.count { depthStarts.append(0) }
                    depthStarts[depth &+ 1] &+= 1
                }

                // 5. A counting sort of the preorder by depth, so each depth's vertices are in
                //    preorder.
                for d in 2 ..< max(depthStarts.count, 2) { depthStarts[d] &+= depthStarts[d &- 1] }
                guard cyclic < n else { return }
                var cursor = Array(depthStarts.dropLast())
                cursor.withUnsafeMutableBufferPointer { cursor in
                    for number in 0 ..< (n &- cyclic) {
                        let depth = Int(remaining[number])
                        byDepth[cursor[depth]] = Int(inPreorder[number])
                        keysByDepth[cursor[depth]] = Int32(truncatingIfNeeded: number)
                        cursor[depth] &+= 1
                    }
                }
            }
            }
            }
            }
            }
            }
            }
            }
        }
        return CycleDecomposition(
            _preimageStarts: preimageStarts, _preimages: preimages, _records: records,
            _byDepth: byDepth, _keysByDepth: keysByDepth, _depthStarts: depthStarts, _cycleStarts: cycleStarts
        )
    }
}
