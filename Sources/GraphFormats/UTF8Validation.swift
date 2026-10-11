/// Checks that `text` is UTF-8, throwing `invalidUTF8` at the first byte of the first bad sequence
/// (where Python's decoder reports it: a lead byte with a bad continuation, a lone continuation, an
/// overlong form, a surrogate, a scalar past U+10FFFF, or a sequence cut by the end).
///
/// With `xmlCharacters`, a scalar XML 1.0 does not allow (a C0 control other than tab, line feed
/// and carriage return; U+FFFE; U+FFFF) is then `syntax` at the first such scalar. Invalid UTF-8
/// anywhere comes first.
@inlinable func _validateUTF8(_ text: UnsafeBufferPointer<UInt8>, xmlCharacters: Bool) throws(ParseError) {
    guard let base = text.baseAddress else { return }
    let n = text.count
    var i = 0
    var firstBadCharacter = -1
    let raw = UnsafeRawPointer(base)
    while i < n {
        // Eight ASCII bytes at a time.
        while i &+ 8 <= n {
            let word = raw.loadUnaligned(fromByteOffset: i, as: UInt64.self)
            if word & 0x8080_8080_8080_8080 != 0 { break }
            if xmlCharacters && firstBadCharacter < 0
                && (word &- 0x2020_2020_2020_2020) & ~word & 0x8080_8080_8080_8080 != 0
            {
                break
            }
            i &+= 8
        }
        if i >= n { break }
        let lead = base[i]
        if lead < 0x80 {
            if xmlCharacters && lead < 0x20 && lead != 0x09 && lead != 0x0A && lead != 0x0D && firstBadCharacter < 0 {
                firstBadCharacter = i
            }
            i &+= 1
            continue
        }
        let width: Int
        var low: UInt8 = 0x80, high: UInt8 = 0xBF
        switch lead {
        case 0xC2 ... 0xDF: width = 2
        case 0xE0: width = 3; low = 0xA0
        case 0xE1 ... 0xEC, 0xEE ... 0xEF: width = 3
        case 0xED: width = 3; high = 0x9F
        case 0xF0: width = 4; low = 0x90
        case 0xF1 ... 0xF3: width = 4
        case 0xF4: width = 4; high = 0x8F
        default: throw ParseError(.invalidUTF8, at: i)
        }
        guard i &+ width <= n else { throw ParseError(.invalidUTF8, at: i) }
        let second = base[i &+ 1]
        guard second >= low && second <= high else { throw ParseError(.invalidUTF8, at: i) }
        var k = 2
        while k < width {
            guard base[i &+ k] & 0xC0 == 0x80 else { throw ParseError(.invalidUTF8, at: i) }
            k &+= 1
        }
        // U+FFFE and U+FFFF are EF BF BE and EF BF BF.
        if xmlCharacters && lead == 0xEF && second == 0xBF && base[i &+ 2] >= 0xBE && firstBadCharacter < 0 {
            firstBadCharacter = i
        }
        i &+= width
    }
    if firstBadCharacter >= 0 { throw ParseError(.syntax, at: firstBadCharacter) }
}
