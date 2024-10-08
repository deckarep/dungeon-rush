const std = @import("std");
const expect = std.testing.expect;

// From https://stackoverflow.com/questions/15500621/c-c-algorithm-to-produce-same-pseudo-random-number-sequences-from-same-seed-on

// NOTE: zig translate-c src/prng.c gave me this file with all the bitCasts which seam superfluous.
// https://www.lagerdata.com/articles/an-intro-to-zigs-integer-casting-for-c-programmers

// Iterative replacement of C -> Zig
// https://tiehu.is/blog/zig1

//pub var nSeed: c_uint = @bitCast(c_uint, @as(c_int, 5323));
pub var nSeed: c_uint = 5323;
pub const prngMax: c_uint = 32767;

pub export fn prngRand() c_uint {
    nSeed = 8253729 *% nSeed +% 2396403;
    //nSeed = (@bitCast(c_uint, @as(c_int, 8253729)) *% nSeed) +% @bitCast(c_uint, @as(c_int, 2396403));
    return nSeed % prngMax;
    //return nSeed % @bitCast(c_uint, @as(c_int, 32767));
}
pub export fn prngSrand(arg_seed: c_uint) void {
    const seed = arg_seed;
    nSeed = seed;
}

test "prngRand advances in a pseudo-random fashion" {
    // Default seed.
    try expect(prngRand() == 20433);
    try expect(prngRand() == 22044);
    try expect(prngRand() == 9937);
    try expect(prngRand() == 30185);
    try expect(prngRand() == 29341);
    // ...infinity

    // Change seed to something else.
    prngSrand(110711);
    try expect(prngRand() == 23163);
    try expect(prngRand() == 5480);
    try expect(prngRand() == 19254);
    try expect(prngRand() == 46);
    try expect(prngRand() == 18769);
    // ...infinity
}
