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

            @inlinable @inline(__always)
            init(_tail: Int32, _root: Int32, _key: Int32) {
                self._tail = _tail
                self._root = _root
                self._key = _key
            }

            @inlinable var tail: Int { @inline(__always) get { Int(_tail) } }
            @inlinable var root: Int { @inline(__always) get { Int(_root) } }
            @inlinable var key: Int { @inline(__always) get { Int(_key) } }
        }

        /// A vertex's state while peeling: its preimages not yet peeled, the size of its subtree
        /// so far, and its successor, in one 12-byte entry so that a step reads one line.
        @frozen
        @usableFromInline
        struct _PeelNode {
            @usableFromInline var remaining: Int32
            @usableFromInline var size: Int32
            @usableFromInline var successor: Int32

            @inlinable @inline(__always)
            init(remaining: Int32, size: Int32, successor: Int32) {
                self.remaining = remaining
                self.size = size
                self.successor = successor
            }
        }

        /// A peeled vertex, its successor and its subtree size, in peeling order, so that the
        /// reverse pass reads neither f nor the sizes.
        @frozen
        @usableFromInline
        struct _PeelEntry {
            @usableFromInline var vertex: Int32
            @usableFromInline var successor: Int32
            @usableFromInline var size: Int32

            @inlinable @inline(__always)
            init(vertex: Int32, successor: Int32, size: Int32) {
                self.vertex = vertex
                self.successor = successor
                self.size = size
            }
        }

        /// A tree vertex and its depth, stored by preorder number for the counting sort by depth.
        @frozen
        @usableFromInline
        struct _PlacedVertex {
            @usableFromInline var vertex: Int32
            @usableFromInline var depth: Int32

            @inlinable @inline(__always)
            init(vertex: Int32, depth: Int32) {
                self.vertex = vertex
                self.depth = depth
            }
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
    /// tail; building it takes 3n more for a moment (two 12-byte entries per vertex).
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
        typealias Node = CycleDecomposition._PeelNode
        typealias Entry = CycleDecomposition._PeelEntry
        typealias Placed = CycleDecomposition._PlacedVertex
        let n = _successors.count
        precondition(n <= Int(Int32.max), "cycleDecomposition() needs fewer than 2³¹ vertices")
        // Arrays every element of which is written before it is read start uninitialized: fresh
        // pages are much of the cost, and a fill would touch each one twice.
        func uninitialized<T>(_: T.Type, _ count: Int) -> [T] {
            [T](unsafeUninitializedCapacity: count) { _, initialized in initialized = count }
        }
        var preimageStarts = [Int](repeating: 0, count: n + 1)
        var preimages = uninitialized(Int.self, n)
        var records = uninitialized(Record.self, n)
        var byDepth = uninitialized(Int.self, n)
        // The depth-0 part is never read: until step 5 fills the rest, it holds each cyclic
        // vertex's next free preorder number, and the part after it counts the depths.
        var keysByDepth = uninitialized(Int32.self, n)
        var depthStarts: [Int] = [0]
        var cycleStarts: [Int] = [0]
        // Scratch, 24 bytes per vertex: each vertex's peeling state, which the vertices by
        // preorder number reuse once the cycles are placed; and the peeling queue.
        let scratch = UnsafeMutableRawPointer.allocate(
            byteCount: n * MemoryLayout<Node>.stride, alignment: MemoryLayout<Node>.alignment)
        defer { scratch.deallocate() }
        let queue = UnsafeMutablePointer<Entry>.allocate(capacity: n)
        defer { queue.deallocate() }
        _successors.withUnsafeBufferPointer { f in
            preimageStarts.withUnsafeMutableBufferPointer { starts in
            preimages.withUnsafeMutableBufferPointer { rows in
            records.withUnsafeMutableBufferPointer { records in
            byDepth.withUnsafeMutableBufferPointer { byDepth in
            keysByDepth.withUnsafeMutableBufferPointer { keysByDepth in
                // 1. In-degrees, each vertex's peeling state, and the leaves into the queue. Then
                //    the preimage rows: inclusive prefix sums (the end of each row), and each
                //    source placed from the end of its row, sources descending, so every row is
                //    ascending and `starts[w]` ends at the start of row w. The queue entry is
                //    written for every vertex and kept only for a leaf: a branch there is
                //    unpredictable, and an entry past the last is overwritten or never read.
                //    (`end` stays below n: some vertex is on a cycle.)
                let node = scratch.bindMemory(to: Node.self, capacity: n)
                for v in 0 ..< n { starts[f[v]] &+= 1 }
                var end = 0
                var sum = 0
                for w in 0 ..< n {
                    let degree = starts[w]
                    let successor = Int32(truncatingIfNeeded: f[w])
                    node[w] = Node(remaining: Int32(truncatingIfNeeded: degree), size: 1, successor: successor)
                    queue[end] = Entry(vertex: Int32(truncatingIfNeeded: w), successor: successor, size: 1)
                    end &+= degree == 0 ? 1 : 0
                    sum &+= degree
                    starts[w] = sum
                }
                starts[n] = n
                var v = n &- 1
                while v >= 0 {
                    let w = f[v]
                    starts[w] &-= 1
                    rows[starts[w]] = v
                    v &-= 1
                }

                // 2. Peel, leaves first; a vertex leaves the queue after all its preimages, so its
                //    subtree size is final when it is queued, and goes in its entry. As in step 1,
                //    the entry is written either way, and `end` advances by the sign bit of the
                //    remaining in-degree minus one: a branch on it mispredicts about half the time
                //    on a random mapping, which cost a third of this step.
                var head = 0
                while head < end {
                    let entry = queue[head]
                    head &+= 1
                    let w = Int(entry.successor)
                    var state = node[w]
                    state.size &+= entry.size
                    state.remaining &-= 1
                    node[w] = state
                    queue[end] = Entry(vertex: entry.successor, successor: state.successor, size: state.size)
                    end &+= Int(UInt32(bitPattern: state.remaining &- 1) >> 31)
                }

                // 3. The cycles (what peeling left), each from its least vertex, in order of least
                //    vertex. Each root's trees get the next run of preorder numbers, handed out
                //    from the end of the run: the root's entry in `keysByDepth` is the last free
                //    number.
                var placed = 0
                var base: Int32 = 0
                for w in 0 ..< n where node[w].remaining > 0 {
                    let component = Int32(truncatingIfNeeded: cycleStarts.count &- 1)
                    var x = w
                    repeat {
                        let state = node[x]
                        node[x].remaining = 0
                        records[x] = Record(_tail: 0, _root: component, _key: Int32(truncatingIfNeeded: placed))
                        keysByDepth[placed] = base &+ state.size &- 2
                        base &+= state.size &- 1
                        byDepth[placed] = x
                        placed &+= 1
                        x = Int(state.successor)
                    } while x != w
                    cycleStarts.append(placed)
                }
                let cyclic = placed
                depthStarts.append(cyclic)

                // 4. Parents first (the peeling order reversed): depth, root and preorder number.
                //    A tree vertex's record holds the last free number of its run until its
                //    children have taken theirs, which leaves its own number. The tree vertices go
                //    to `byNumber` with their depths, by preorder number, and each depth is
                //    counted after the cyclic part of `keysByDepth`. (A breadth-first search from
                //    the cycles, which lays each depth out in preorder directly, took twice as
                //    long on a random mapping: it reads each parent's row and record at random. A
                //    16-byte build record holding the next free number beside the key, copied into
                //    the records at the end, took about 1.3 times as long as this.)
                let byNumber = scratch.bindMemory(to: Placed.self, capacity: n)
                var deepest: Int32 = 0
                var i = end
                while i > 0 {
                    i &-= 1
                    let entry = queue[i]
                    let p = Int(entry.successor)
                    let parent = records[p]
                    let last: Int32
                    let root: Int32
                    if parent._tail == 0 {
                        last = keysByDepth[Int(parent._key)]
                        keysByDepth[Int(parent._key)] = last &- entry.size
                        root = entry.successor
                    } else {
                        last = parent._key
                        records[p]._key = last &- entry.size
                        root = parent._root
                    }
                    let depth = parent._tail &+ 1
                    let number = last &- entry.size &+ 1
                    records[Int(entry.vertex)] = Record(_tail: depth, _root: root, _key: last)
                    byNumber[Int(number)] = Placed(vertex: entry.vertex, depth: depth)
                    // A child is at most one deeper than any depth so far.
                    if depth > deepest {
                        keysByDepth[cyclic &+ Int(deepest)] = 0
                        deepest = depth
                    }
                    keysByDepth[cyclic &+ Int(depth) &- 1] &+= 1
                }
                for d in 0 ..< Int(deepest) { depthStarts.append(Int(keysByDepth[cyclic &+ d])) }

                // 5. A counting sort of the preorder by depth, so each depth's vertices are in
                //    preorder.
                for d in 2 ..< max(depthStarts.count, 2) { depthStarts[d] &+= depthStarts[d &- 1] }
                guard cyclic < n else { return }
                var cursor = Array(depthStarts.dropLast())
                cursor.withUnsafeMutableBufferPointer { cursor in
                    for number in 0 ..< (n &- cyclic) {
                        let vertex = byNumber[number]
                        let depth = Int(vertex.depth)
                        byDepth[cursor[depth]] = Int(vertex.vertex)
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
        return CycleDecomposition(
            _preimageStarts: preimageStarts, _preimages: preimages, _records: records,
            _byDepth: byDepth, _keysByDepth: keysByDepth, _depthStarts: depthStarts, _cycleStarts: cycleStarts
        )
    }
}
