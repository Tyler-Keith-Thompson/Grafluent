// The upkeep of GraphProtocols' shared map storage (`_AttachedMaps`) on its fast paths, the dense
// maps of trivial values moved as raw bytes (strides 8 and 16), and on the general paths they fall
// back to (other strides, counts other than 1, a full buffer, a shared one), each checked against a
// plain array kept in step; and the generation stamp told apart by storage. See README.md.

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

    @Test("A generation told apart by storage: untracked until a mutation, tracked by lineage once its storage is empty")
    func storageGenerations() {
        final class Storage {}
        let storage = Storage()
        var stamp = _GenerationStamp()
        // Never mutated, with storage: untracked.
        #expect(!stamp.generation(storage: storage).isCurrent(for: stamp.generation(storage: storage)))
        stamp.advanceVersion()
        let first = stamp.generation(storage: storage)
        #expect(first.isCurrent(for: stamp.generation(storage: storage)))
        // Other storage is another graph's (or a copy's after it mutated).
        #expect(!first.isCurrent(for: stamp.generation(storage: Storage())))
        stamp.advanceVersion(storageIsEmpty: false)
        #expect(!first.isCurrent(for: stamp.generation(storage: storage)))
        // Storage now empty: the lineage keeps the graph tracked, and moves on.
        let beforeEmpty = stamp.generation(storage: storage)
        stamp.advanceVersion(storageIsEmpty: true)
        #expect(stamp.generation(storage: nil).isCurrent(for: stamp.generation(storage: nil)))
        #expect(!beforeEmpty.isCurrent(for: stamp.generation(storage: nil)))
        // A stamp without a mutation is tracked, and no two stamps share a lineage.
        var built = _GenerationStamp(), other = _GenerationStamp()
        built.stamp()
        other.stamp()
        #expect(built.generation.isCurrent(for: built.generation))
        #expect(!built.generation.isCurrent(for: other.generation))
        #expect(!GraphGeneration.untracked.isCurrent(for: .untracked))
        #expect("\(built.generation)" == "GraphGeneration(version: 0)" && "\(GraphGeneration.untracked)" == "GraphGeneration(untracked)")
    }
}
