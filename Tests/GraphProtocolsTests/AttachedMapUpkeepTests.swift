// The upkeep of GraphProtocols' shared map storage (`_AttachedMaps`) on its fast paths, the dense
// maps of trivial values moved as raw bytes (strides 8 and 16), and on the general paths they fall
// back to (other strides, counts other than 1, a full buffer, a shared one), each checked against a
// plain array kept in step; a copy that replaces the table it shares, with every upkeep on the
// other copy after it; and the generation stamp. See README.md.

import GraphProtocols
import Testing

@Suite("Attached map upkeep")
struct AttachedMapUpkeepTests {
    @Test("Appends, swap-removes and resets of trivial dense maps match arrays kept in step, at every stride")
    func trivialUpkeep() {
        var maps = _AttachedMaps()
        let (ints, _) = maps.add(default: 7, layout: .dense, count: 2)
        let (optionals, _) = maps.add(default: Double?.none, layout: .dense, count: 2)
        let (flags, _) = maps.add(default: true, layout: .dense, count: 2)
        let k = (ints: maps.index(of: ints, hint: 0), optionals: maps.index(of: optionals, hint: 1), flags: maps.index(of: flags, hint: 2))
        var intModel = [7, 7], optionalModel: [Double?] = [nil, nil], flagModel = [true, true]
        // Past the initial capacity of 2, so the appends grow every buffer.
        // The first values differ from the defaults, so an append that copied anything else shows.
        maps.setValue(-1, at: 0, in: k.ints, layout: .dense)
        maps.setValue(Double?(-1), at: 0, in: k.optionals, layout: .dense)
        maps.setValue(false, at: 0, in: k.flags, layout: .dense)
        intModel[0] = -1
        optionalModel[0] = -1
        flagModel[0] = false
        for step in 0 ..< 40 {
            maps.appendDefaults(count: 1)
            intModel.append(7)
            optionalModel.append(nil)
            flagModel.append(true)
            let p = intModel.count - 1
            #expect(maps.value(Int.self, at: p, in: k.ints, layout: .dense) == 7)
            #expect(maps.value(Double?.self, at: p, in: k.optionals, layout: .dense) == nil)
            #expect(maps.value(Bool.self, at: p, in: k.flags, layout: .dense))
            maps.setValue(step, at: p, in: k.ints, layout: .dense)
            maps.setValue(Double?(Double(step) / 2), at: p, in: k.optionals, layout: .dense)
            maps.setValue(step % 3 == 0, at: p, in: k.flags, layout: .dense)
            intModel[p] = step
            optionalModel[p] = Double(step) / 2
            flagModel[p] = step % 3 == 0
        }
        // Several at once, within the capacity the growth left.
        maps.appendDefaults(count: 3)
        intModel += [7, 7, 7]
        optionalModel += [nil, nil, nil]
        flagModel += [true, true, true]
        // The first, middle ones, and the last (which only drops).
        for choose in [{ (_: Int) in 0 }, { _ in 5 }, { _ in 40 }, { (count: Int) in count - 1 }, { _ in 3 }, { _ in 3 }] {
            let offset = choose(intModel.count)
            maps.swapRemove(at: offset)
            let last = intModel.removeLast(), lastOptional = optionalModel.removeLast(), lastFlag = flagModel.removeLast()
            if offset < intModel.count {
                intModel[offset] = last
                optionalModel[offset] = lastOptional
                flagModel[offset] = lastFlag
            }
        }
        for offset in [1, 2, intModel.count - 1] {
            maps.reset(at: offset)
            intModel[offset] = 7
            optionalModel[offset] = nil
            flagModel[offset] = true
        }
        #expect(Array(maps.storage(Int.self, in: k.ints).dense) == intModel)
        #expect(Array(maps.storage(Double?.self, in: k.optionals).dense) == optionalModel)
        #expect(Array(maps.storage(Bool.self, in: k.flags).dense) == flagModel)
    }

    @Test("A snapshot and a copy keep their values through every kind of upkeep")
    func sharedBuffers() {
        // Fresh maps for each case, with room to append in place, so no flag is left over from
        // another case.
        func fresh() -> _AttachedMaps {
            var maps = _AttachedMaps()
            _ = maps.add(default: 0, layout: .dense, count: 4)
            _ = maps.add(default: 0.5, layout: .dense, count: 4)
            maps.reserveCapacity(16)
            for p in 0 ..< 4 {
                maps.setValue(p + 1, at: p, in: 0, layout: .dense)
                maps.setValue(Double(p) + 1.5, at: p, in: 1, layout: .dense)
            }
            return maps
        }
        let expected = ([1, 2, 3, 4], [1.5, 2.5, 3.5, 4.5])
        let operations: [(String, (inout _AttachedMaps) -> Void)] = [
            ("appendDefaults", { $0.appendDefaults(count: 1) }),
            ("swapRemove", { $0.swapRemove(at: 0) }),
            ("reset", { $0.reset(at: 1) }),
        ]
        for (name, operation) in operations {
            // A snapshot taken before the upkeep keeps the values it had.
            var snapshotted = fresh()
            let intSnapshot = snapshotted.storage(Int.self, in: 0), doubleSnapshot = snapshotted.storage(Double.self, in: 1)
            operation(&snapshotted)
            #expect(Array(intSnapshot.dense) == expected.0 && Array(doubleSnapshot.dense) == expected.1, "\(name)")
            // So does a copy of the maps.
            var copied = fresh()
            let copy = copied
            operation(&copied)
            #expect(Array(copy.storage(Int.self, in: 0).dense) == expected.0, "\(name)")
            #expect(Array(copy.storage(Double.self, in: 1).dense) == expected.1, "\(name)")
            // And a copy made before a map was attached, which shares the earlier maps' buffers.
            var grown = fresh()
            let earlier = grown
            _ = grown.add(default: 9, layout: .dense, count: 4)
            operation(&grown)
            #expect(Array(earlier.storage(Int.self, in: 0).dense) == expected.0, "\(name)")
            #expect(Array(earlier.storage(Double.self, in: 1).dense) == expected.1, "\(name)")
        }
    }

    @Test("A copy that replaces the table it shares leaves the other copy's buffers alone: every trigger, then every upkeep on the other")
    func replacedTables() {
        // `keeper` and `replacer` share one table. `replacer` replaces it (a trigger), so the
        // buffers are now listed by two tables, and `keeper`, which holds the old table alone, must
        // copy each before it writes it. Then `keeper` runs an upkeep operation, and each copy's
        // values are checked against a model of its own.
        struct Model<A, B> {
            var a: [A]
            var b: [B]
        }
        func check<A: Equatable & Sendable, B: Equatable & Sendable>(
            _ kind: String, layout: _MapLayout, _ a: (default: A, values: [A]), _ b: (default: B, values: [B])
        ) {
            let count = 4
            let dense = layout == .dense
            func fresh() -> _AttachedMaps {
                var maps = _AttachedMaps()
                _ = maps.add(default: a.default, layout: layout, count: dense ? count : 0)
                _ = maps.add(default: b.default, layout: layout, count: dense ? count : 0)
                // A third map, for the trigger that detaches one.
                _ = maps.add(default: 0, layout: layout, count: dense ? count : 0)
                // Room to append in place, so an append takes the fast path.
                maps.reserveCapacity(16)
                for p in 0 ..< count {
                    maps.setValue(a.values[p], at: p, in: 0, layout: layout)
                    maps.setValue(b.values[p], at: p, in: 1, layout: layout)
                }
                return maps
            }
            func read(_ maps: _AttachedMaps, _ count: Int) -> Model<A, B> {
                Model(
                    a: (0 ..< count).map { maps.value(A.self, at: $0, in: 0, layout: layout) },
                    b: (0 ..< count).map { maps.value(B.self, at: $0, in: 1, layout: layout) })
            }
            func released(_ model: inout Model<A, B>, at p: Int) {
                if !_isPOD(A.self) { model.a[p] = a.default }
                if !_isPOD(B.self) { model.b[p] = b.default }
            }
            let initial = Model(a: Array(a.values.prefix(count)), b: Array(b.values.prefix(count)))
            let triggers: [(String, (inout _AttachedMaps) -> Void, (inout Model<A, B>) -> Void)] = [
                ("attach", { _ = $0.add(default: 1.5, layout: layout, count: dense ? count : 0) }, { _ in }),
                ("detach", { $0.remove($0._entries[2].token, hint: 2) }, { _ in }),
                ("setValue", { $0.setValue(a.values[4], at: 0, in: 0, layout: layout) }, { $0.a[0] = a.values[4] }),
                ("release", { $0.release(at: 1) }, { released(&$0, at: 1) }),
                dense
                    ? ("appendDefaults", { $0.appendDefaults(count: 1) }, { $0.a.append(a.default); $0.b.append(b.default) })
                    : ("reset", { $0.reset(at: 2) }, { $0.a[2] = a.default; $0.b[2] = b.default }),
            ]
            var operations: [(String, (inout _AttachedMaps) -> Void, (inout Model<A, B>) -> Void)] = [
                ("reset", { $0.reset(at: 1) }, { $0.a[1] = a.default; $0.b[1] = b.default }),
                ("release", { $0.release(at: 2) }, { released(&$0, at: 2) }),
                ("setValue", { $0.setValue(a.values[5], at: 3, in: 0, layout: layout) }, { $0.a[3] = a.values[5] }),
                ("reserveCapacity", { $0.reserveCapacity(64) }, { _ in }),
                ("removeAll", { $0.removeAll(keepingCapacity: true) }, { $0.a = dense ? [] : Array(repeating: a.default, count: 4); $0.b = dense ? [] : Array(repeating: b.default, count: 4) }),
            ]
            if dense {
                operations += [
                    ("appendDefaults(count: 1)", { $0.appendDefaults(count: 1) }, { $0.a.append(a.default); $0.b.append(b.default) }),
                    ("appendDefaults(count: 3)", { $0.appendDefaults(count: 3) }, { $0.a += Array(repeating: a.default, count: 3); $0.b += Array(repeating: b.default, count: 3) }),
                    ("swapRemove(at: 0)", { $0.swapRemove(at: 0) }, { $0.a.swapAt(0, 3); $0.a.removeLast(); $0.b.swapAt(0, 3); $0.b.removeLast() }),
                    ("swapRemove of the last", { $0.swapRemove(at: 3) }, { $0.a.removeLast(); $0.b.removeLast() }),
                ]
            } else {
                operations.append(("freePage", { $0.freePage(0) }, { $0.a = Array(repeating: a.default, count: 4); $0.b = Array(repeating: b.default, count: 4) }))
            }
            for (trigger, replace, replaced) in triggers {
                for (name, operation, operated) in operations {
                    var keeper = fresh()
                    var replacer = keeper
                    replace(&replacer)
                    operation(&keeper)
                    var keeperModel = initial, replacerModel = initial
                    operated(&keeperModel)
                    replaced(&replacerModel)
                    let keeperValues = read(keeper, dense ? keeperModel.a.count : count)
                    let replacerValues = read(replacer, dense ? replacerModel.a.count : count)
                    #expect(keeperValues.a == keeperModel.a && keeperValues.b == keeperModel.b, "\(kind): \(trigger) on the copy, then \(name) on the original")
                    #expect(replacerValues.a == replacerModel.a && replacerValues.b == replacerModel.b, "\(kind): \(trigger) on the copy, then \(name) on the original")
                    // And the other way round: the copy replaces the table, then upkeep on itself.
                    var other = fresh()
                    var otherCopy = other
                    replace(&other)
                    operation(&otherCopy)
                    let otherValues = read(other, dense ? replacerModel.a.count : count)
                    let otherCopyValues = read(otherCopy, dense ? keeperModel.a.count : count)
                    #expect(otherValues.a == replacerModel.a && otherValues.b == replacerModel.b, "\(kind): \(trigger) on the original, then \(name) on the copy")
                    #expect(otherCopyValues.a == keeperModel.a && otherCopyValues.b == keeperModel.b, "\(kind): \(trigger) on the original, then \(name) on the copy")
                }
            }
        }
        // Trivial values at strides 8 and 16: every fast path.
        check("Int and Double?", layout: .dense, (0, [10, 20, 30, 40, 50, 60]), (Double?.none, [1.5, 2.5, 3.5, 4.5, 5.5, 6.5]))
        // A value holding a reference, and stride 4: the general paths.
        check("String and Int32", layout: .dense, ("", ["a", "b", "c", "d", "e", "f"]), (Int32(0), [1, 2, 3, 4, 5, 6]))
        // Paged maps: the general paths of the paged layout.
        check("paged Int and String", layout: .paged, (0, [10, 20, 30, 40, 50, 60]), ("", ["a", "b", "c", "d", "e", "f"]))
    }

    @Test("A copy that replaces the table it shares leaves a snapshot of the other copy's values intact")
    func replacedTableSnapshot() {
        var keeper = _AttachedMaps()
        _ = keeper.add(default: 7, layout: .dense, count: 2)
        keeper.setValue(1, at: 0, in: 0, layout: .dense)
        var replacer = keeper
        _ = replacer.add(default: 0.5, layout: .dense, count: 2)
        let snapshot = replacer.storage(Int.self, in: 0)
        // Enough appends to outgrow the buffer: an append in place would free the snapshot's values.
        for _ in 0 ..< 1000 { keeper.appendDefaults(count: 1) }
        keeper.swapRemove(at: 0)
        keeper.reset(at: 1)
        #expect(Array(snapshot.dense) == [1, 7])
        #expect(Array(replacer.storage(Int.self, in: 0).dense) == [1, 7])
        #expect(keeper.storage(Int.self, in: 0).dense.count == 1001 && keeper.value(Int.self, at: 0, in: 0, layout: .dense) == 7)
    }

    @Test("The generation stamp: untracked until a mutation; a write in place is a version, a moved, copied or empty identity array a new lineage")
    func generationStamps() {
        var stamp = _GenerationStamp()
        // Never mutated: untracked.
        #expect(!stamp.generation.isCurrent(for: stamp.generation) && stamp.generation == .untracked)
        var storage = ContiguousArray<Int>()
        storage.reserveCapacity(8)
        storage.append(1)
        // The first mutation knows no address yet: a lineage of its own.
        stamp.advance(writing: storage)
        let first = stamp.generation
        #expect(first.isCurrent(for: stamp.generation) && first._lineage != 0 && first._version == 0)
        // A write in place: the next version of the lineage.
        storage.append(2)
        stamp.advance(writing: storage)
        let second = stamp.generation
        #expect(!first.isCurrent(for: second) && second._lineage == first._lineage && second._version == 1)
        // A copy's write moves its array: a new lineage, and the original, now unique, keeps its own.
        var copy = storage, copyStamp = stamp
        copy.append(3)
        copyStamp.advance(writing: copy)
        storage.append(4)
        stamp.advance(writing: storage)
        #expect(copyStamp.generation._lineage != first._lineage && stamp.generation._lineage == first._lineage)
        #expect(!copyStamp.generation.isCurrent(for: stamp.generation))
        // A move without a structural mutation keeps the generation; the next mutation starts a lineage.
        let beforeMove = stamp.generation
        storage.reserveCapacity(1000)
        stamp.storageMayHaveMoved(storage)
        #expect(beforeMove.isCurrent(for: stamp.generation))
        storage.append(5)
        stamp.advance(writing: storage)
        #expect(stamp.generation._lineage != first._lineage && stamp.generation._version == 0)
        // Reserving within the capacity moves nothing, and keeps the lineage.
        let unmoved = stamp.generation
        storage.reserveCapacity(10)
        stamp.storageMayHaveMoved(storage)
        storage.append(6)
        stamp.advance(writing: storage)
        #expect(stamp.generation._lineage == unmoved._lineage && stamp.generation._version == 1)
        // Made unique and empty, an array never matches, even its own buffer kept with its capacity:
        // an empty array may share one buffer with every other.
        storage.removeAll(keepingCapacity: true)
        stamp.advance(owning: &storage)
        let emptied = stamp.generation
        stamp.advance(owning: &storage)
        #expect(stamp.generation._lineage != emptied._lineage && emptied._lineage != unmoved._lineage)
        var empty = ContiguousArray<Int>()
        stamp.advance(owning: &empty)
        let once = stamp.generation
        stamp.advance(owning: &empty)
        #expect(stamp.generation._lineage != once._lineage)
        // advance(owning:) makes a shared array unique first: a new lineage.
        var owned = ContiguousArray([1, 2, 3])
        var ownedStamp = _GenerationStamp()
        ownedStamp.advance(writing: owned)
        ownedStamp.advance(owning: &owned)
        let unique = ownedStamp.generation
        #expect(unique._version == 1)
        let sharer = owned
        ownedStamp.advance(owning: &owned)
        #expect(ownedStamp.generation._lineage != unique._lineage && sharer == owned)
        // stamp(): tracked at once, and no two stamps share a lineage.
        var built = _GenerationStamp(), other = _GenerationStamp()
        built.stamp()
        other.stamp()
        #expect(built.generation.isCurrent(for: built.generation))
        #expect(!built.generation.isCurrent(for: other.generation) && built.generation != other.generation)
        #expect(!GraphGeneration.untracked.isCurrent(for: .untracked))
        // A move without a structural mutation forgets the address, so a later buffer at the old
        // address, which the allocator may hand back, is not taken for the old one.
        var reused = 0
        for _ in 0 ..< 64 where reused == 0 {
            var original = ContiguousArray<Int>()
            original.reserveCapacity(4)
            original.append(1)
            var originalStamp = _GenerationStamp()
            originalStamp.advance(writing: original)
            let oldAddress = original.withUnsafeBufferPointer { UInt(bitPattern: $0.baseAddress) }
            var moved = original, movedStamp = originalStamp
            moved.reserveCapacity(64)
            movedStamp.storageMayHaveMoved(moved)
            // The original writes in place, the next version of the lineage, and then lets its buffer go.
            original.append(2)
            originalStamp.advance(writing: original)
            let taken = originalStamp.generation
            original = []
            // The moved copy takes a buffer of the old one's size, often at the old address.
            moved.removeAll()
            moved.reserveCapacity(4)
            moved.append(3)
            guard moved.withUnsafeBufferPointer({ UInt(bitPattern: $0.baseAddress) }) == oldAddress else { continue }
            reused += 1
            movedStamp.advance(writing: moved)
            #expect(!movedStamp.generation.isCurrent(for: taken))
        }
        // A generation is two integers.
        #expect(_isPOD(GraphGeneration.self) && MemoryLayout<GraphGeneration>.size == 16)
    }
}
