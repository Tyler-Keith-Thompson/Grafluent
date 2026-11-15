// The logarithm behind every geometric skip (G(n, p), the random bipartite graph, the stochastic
// block model and Chung–Lu) is SwiftPRNG's Fdlibm.log, so a seed gives the same graph on every
// platform. These pin its bits on the inputs the skips take: 1, subnormals, uniform draws and
// 1 − p. The expected bits come from `fdlibm_log` in Tests/Catalogs/RandomGraphs/ref.py, the
// catalog's reference model; the last three inputs are draws where macOS's libm `log` rounds the
// last bit the other way.

import Distributions
import Testing

@Suite("RandomGraphs: the skips' logarithm")
struct SkipLogarithmTests {
    @Test("the skips' logarithm returns the same bits on every platform", arguments: [
        // 1
        (0x3FF0_0000_0000_0000, 0x0000_0000_0000_0000),
        // The least subnormal (2⁻¹⁰⁷⁴), the greatest subnormal and the least normal.
        (0x0000_0000_0000_0001, 0xC087_4385_446D_71C3),
        (0x000F_FFFF_FFFF_FFFF, 0xC086_232B_DD7A_BCD2),
        (0x0010_0000_0000_0000, 0xC086_232B_DD7A_BCD2),
        // 2⁻⁵³, the least nonzero uniform draw.
        (0x3CA0_0000_0000_0000, 0xC042_5E4F_7B27_37FA),
        // 0.5
        (0x3FE0_0000_0000_0000, 0xBFE6_2E42_FEFA_39EF),
        // 0.9, the 1 − p of p = 0.1.
        (0x3FEC_CCCC_CCCC_CCCD, 0xBFBA_F8E8_210A_415C),
        // 1 − 2⁻⁵³, the greatest draw below 1.
        (0x3FEF_FFFF_FFFF_FFFF, 0xBCA0_0000_0000_0000),
        // Draws where macOS's libm rounds the last bit the other way.
        (0x3FE9_B4B1_F77D_D0FC, 0xBFCC_08C5_7170_33E2),
        (0x3FE3_6963_EEFB_A1F8, 0xBFDF_FDB8_9108_497C),
        (0x3FDE_6E5F_D29F_0540, 0xBFE7_CA11_10A7_43D4),
    ] as [(UInt64, UInt64)])
    func logarithmBits(input: UInt64, expected: UInt64) {
        let x = Double(bitPattern: input)

        let actual = Fdlibm.log(x).bitPattern

        #expect(actual == expected)
    }
}
