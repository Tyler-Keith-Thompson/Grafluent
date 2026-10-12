// Numbers, against the standard library: a decimal reads as `Double(_:)` reads it (correctly
// rounded, Eisel–Lemire with a fallback); a double writes the shortest digits that round-trip,
// the same digits as `description` (Schubfach), on random bit patterns, both ends of every binade,
// subnormals and the band 9·10¹⁵ – 2⁵⁴ where Swift's and Python's layouts part; and every double
// written in every format that holds it reads back to the same bits. Seeded; see README.md.

import GrafluentTestSupport
import GraphFormats
import GraphProtocols
import Multigraphs
import Testing

@Suite("GraphFormats numbers")
struct GraphFormatsNumberTests {
    @Test("A decimal column reads as Double(_:) reads the same text, to the bit", .timeLimit(.minutes(1)), arguments: 0 ..< 4 as Range<UInt>)
    func decimalsMatchDoubleInit(seed: UInt) throws {
        /// The significant digits of a decimal text (no leading or trailing zeros) and the decimal
        /// exponent of the first: `"0.00120"` is `("12", -3)`, `"1.5e+20"` is `("15", 20)`.
        func decimal(_ text: String) -> (digits: String, exponent: Int) {
            var mantissa = Substring(text)
            var exponent = 0
            if let e = text.firstIndex(where: { $0 == "e" || $0 == "E" }) {
                exponent = Int(text[text.index(after: e)...])!
                mantissa = text[..<e]
            }
            if mantissa.hasPrefix("-") { mantissa = mantissa.dropFirst() }
            let parts = mantissa.split(separator: ".", omittingEmptySubsequences: false)
            var all = String(parts[0]) + (parts.count > 1 ? String(parts[1]) : "")
            var point = parts[0].count
            while all.hasPrefix("0") {
                all.removeFirst()
                point -= 1
            }
            while all.hasSuffix("0") { all.removeLast() }
            return (all, exponent + point - 1)
        }
        var rng = SeededRandomNumberGenerator(seed: seed)
        var texts: [String] = [
            "4.9406564584124654e-324", "2.4703282292062327e-324", "2.4703282292062328e-324", "2.2250738585072011e-308",
            "2.2250738585072012e-308", "1.7976931348623157e308", "1.7976931348623158e308", "1.7976931348623159e308",
            "9007199254740993.0", "9007199254740992.5", "0.1", "-0.0", "1e-400", "1e400", "123456789012345678901234567890.0",
            "0.000000000000000000000000000000000000000000001e45", "7.0e-10", "89255.0e-22", "8.988465674311580536566680e307",
        ]
        let digits = Array("0123456789")
        for _ in 0 ..< 4_000 {
            switch Int.random(in: 0 ..< 3, using: &rng) {
            case 0:
                // Random digits, a point somewhere, an exponent across the whole range.
                let count = Int.random(in: 1 ... 30, using: &rng)
                var mantissa = String((0 ..< count).map { _ in digits[Int.random(in: 0 ..< 10, using: &rng)] })
                let point = Int.random(in: 0 ... count, using: &rng)
                mantissa.insert(".", at: mantissa.index(mantissa.startIndex, offsetBy: point))
                if mantissa.hasPrefix(".") { mantissa = "0" + mantissa }
                let sign = Bool.random(using: &rng) ? "-" : ""
                texts.append("\(sign)\(mantissa)e\(Int.random(in: -360 ... 330, using: &rng))")
            case 1:
                // Near a tie: a double's shortest digits, then 5, zeros, and a last digit.
                let x = Double(bitPattern: UInt64.random(in: 1 ..< 0x7FF0_0000_0000_0000, using: &rng))
                let (shortest, exponent) = decimal(x.description)
                let tail = "5" + String(repeating: "0", count: Int.random(in: 0 ... 25, using: &rng))
                    + ["", "1", "9"][Int.random(in: 0 ..< 3, using: &rng)]
                let all = shortest + String(repeating: "0", count: max(0, 17 - shortest.count)) + tail
                texts.append("\(all.first!).\(all.dropFirst())e\(exponent)")
            default:
                // A double's own digits, with zeros around them.
                let x = Double(bitPattern: UInt64.random(in: 1 ..< 0x7FF0_0000_0000_0000, using: &rng))
                let (shortest, exponent) = decimal(x.description)
                texts.append("000\(shortest.first!).\(shortest.dropFirst())000e\(exponent)")
            }
        }
        let file = texts.enumerated().map { "\($0) \($0) \($1)" }.joined(separator: "\n")
        var read: [Int: Double] = [:]
        _ = try DirectedPseudograph<Int>(edgeList: file.utf8, columns: ["x"], edgeAttribute: { p, _, value in
            if case .double(let d) = value { read[p] = d }
        })
        for (k, text) in texts.enumerated() {
            let expected = Double(text)!
            #expect(read[k]?.bitPattern == expected.bitPattern, "\(text): read \(String(describing: read[k])), Double(_:) \(expected)")
        }
    }

    @Test("Written doubles have description's digits and read back to the same bits, in every format", .timeLimit(.minutes(1)), arguments: 0 ..< 4 as Range<UInt>)
    func writtenDoublesRoundTrip(seed: UInt) throws {
        /// The significant digits of a decimal text (no leading or trailing zeros) and the decimal
        /// exponent of the first: `"0.00120"` is `("12", -3)`, `"1.5e+20"` is `("15", 20)`.
        func decimal(_ text: String) -> (digits: String, exponent: Int) {
            var mantissa = Substring(text)
            var exponent = 0
            if let e = text.firstIndex(where: { $0 == "e" || $0 == "E" }) {
                exponent = Int(text[text.index(after: e)...])!
                mantissa = text[..<e]
            }
            if mantissa.hasPrefix("-") { mantissa = mantissa.dropFirst() }
            let parts = mantissa.split(separator: ".", omittingEmptySubsequences: false)
            var all = String(parts[0]) + (parts.count > 1 ? String(parts[1]) : "")
            var point = parts[0].count
            while all.hasPrefix("0") {
                all.removeFirst()
                point -= 1
            }
            while all.hasSuffix("0") { all.removeLast() }
            return (all, exponent + point - 1)
        }
        var rng = SeededRandomNumberGenerator(seed: seed)
        var values: [Double] = [0, -0.0, .infinity, -.infinity, .nan, .leastNonzeroMagnitude, .leastNormalMagnitude,
                                .greatestFiniteMagnitude, 1e16, 9.0e15, 9_007_199_254_740_992, 1e-5, 1e-4]
        for e in 0 ..< 2_047 {
            for fraction: UInt64 in [0, 1, (1 << 52) - 1] { values.append(Double(bitPattern: UInt64(e) << 52 | fraction)) }
        }
        for _ in 0 ..< 3_000 {
            values.append(Double(bitPattern: UInt64.random(in: 0 ... .max, using: &rng)))
            values.append(Double.random(in: 9.0e15 ... 1.8014398509481984e16, using: &rng))
            values.append(Double(bitPattern: UInt64.random(in: 0 ..< 1 << 52, using: &rng)))
        }
        for x in [1e16, 9.0e15, 9_007_199_254_740_992.0] {
            var below = x, above = x
            for _ in 0 ..< 20 {
                below = below.nextDown
                above = above.nextUp
                values.append(below)
                values.append(above)
            }
        }
        let m = values.count
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: Array(repeating: DirectedEdge(from: 0, to: 1), count: m))

        // The edge list writes Python's repr: its digits are description's, positional exactly for
        // decimal exponents -4 ..< 16, and every value reads back.
        var edgeList = ""
        graph.writeEdgeList(to: &edgeList, columns: ["x"], edgeAttributes: { [("x", .double(values[$0]))] })
        let written = edgeList.split(separator: "\n").map { String($0.split(separator: " ")[2]) }
        for (k, x) in values.enumerated() where x.isFinite && x != 0 {
            let text = written[k]
            #expect(decimal(text) == decimal(x.description), "\(text) against \(x.description)")
            let exponent = decimal(x.description).exponent
            #expect(text.contains("e") == (exponent < -4 || exponent >= 16), "\(text)")
        }
        var listed = [Double](repeating: 0, count: m)
        _ = try DirectedPseudograph<Int>(edgeList: edgeList.utf8, columns: ["x"], edgeAttribute: { p, _, value in
            if case .double(let d) = value { listed[p] = d }
        })
        // Matrix Market writes SciPy's form; GraphML and node-link JSON Python's.
        var matrixMarket = ""
        graph.writeMatrixMarket(to: &matrixMarket, weight: { values[$0] })
        var fromMatrix = [Double](repeating: 0, count: m)
        _ = try DirectedPseudograph<Int>(matrixMarket: matrixMarket.utf8, edgeAttribute: { p, _, value in
            if case .double(let d) = value { fromMatrix[p] = d }
        })
        var graphML = ""
        graph.writeGraphML(to: &graphML, edgeAttributes: { [("x", .double(values[$0]))] })
        var fromGraphML = [Double](repeating: 0, count: m)
        _ = try DirectedPseudograph<Int>(graphML: graphML.utf8, vertex: { Int($0) }, edgeAttribute: { p, _, value in
            if case .double(let d) = value { fromGraphML[p] = d }
        })
        var nodeLink = ""
        graph.writeNodeLinkJSON(to: &nodeLink, edgeAttributes: { [("x", .double(values[$0].isFinite ? values[$0] : 0))] })
        var fromJSON = [Double](repeating: 0, count: m)
        _ = try DirectedPseudograph<Int>(nodeLinkJSON: nodeLink.utf8, edgeAttribute: { p, _, value in
            if case .double(let d) = value { fromJSON[p] = d }
        })
        for (k, x) in values.enumerated() {
            for (name, back) in [("edge list", listed[k]), ("Matrix Market", fromMatrix[k]), ("GraphML", fromGraphML[k])] {
                #expect(x.isNaN ? back.isNaN : back.bitPattern == x.bitPattern, "\(name): \(x) read back as \(back)")
            }
            let finite = x.isFinite ? x : 0
            #expect(fromJSON[k].bitPattern == finite.bitPattern, "node-link: \(finite) read back as \(fromJSON[k])")
        }
    }

    @Test("Python's layout around 10¹⁶ and 2⁵³, where description's switches to an exponent earlier")
    func pythonLayoutBand() {
        let cases: [(Double, String)] = [
            (9.5e15, "9500000000000000.0"), (9_007_199_254_740_992, "9007199254740992.0"), (9_007_199_254_740_994, "9007199254740994.0"),
            (9_999_999_999_999_998, "9999999999999998.0"), (1e16, "1e+16"), (1.0000000000000002e16, "1.0000000000000002e+16"),
            (123_456_789_012_345.67, "123456789012345.67"), (0.0001, "0.0001"), (0.00001, "1e-05"), (5e-324, "5e-324"),
            (1.7976931348623157e308, "1.7976931348623157e+308"), (2.5, "2.5"), (100, "100.0"), (-0.0, "-0.0"),
        ]
        var output = ""
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: Array(repeating: DirectedEdge(from: 0, to: 1), count: cases.count))
        graph.writeEdgeList(to: &output, columns: ["x"], edgeAttributes: { [("x", .double(cases[$0].0))] })
        #expect(output == cases.map { "0 1 \($0.1)\n" }.joined())
        var scipy = ""
        let three: [Double] = [9.5e15, 1e16, 0.00001]
        DirectedPseudograph<Int>(vertices: 0 ..< 2, edges: Array(repeating: DirectedEdge(from: 0, to: 1), count: 3))
            .writeMatrixMarket(to: &scipy, weight: { three[$0] })
        #expect(scipy.hasSuffix("2 2 3\n1 2 9.5E15\n1 2 1E16\n1 2 1E-5\n"))
    }
}
