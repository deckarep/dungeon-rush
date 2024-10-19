// Open Source Initiative OSI - The MIT License (MIT):Licensing

// The MIT License (MIT)
// Copyright (c) 2024 Ralph Caraveo (deckarep@gmail.com)

// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

const std = @import("std");

pub var nSeed: c_uint = 5323;
pub const PRNG_MAX: c_uint = 32767;

pub export fn prngRand() c_uint {
    nSeed = 8253729 *% nSeed +% 2396403;
    return nSeed % PRNG_MAX;
}
pub export fn prngSrand(arg_seed: c_uint) void {
    const seed = arg_seed;
    nSeed = seed;
}

// TODO: perhaps utilize Zig's random stuff later.
// This stuff below is not properly tested.
//var internalRand: ?std.Random = null;

// pub fn prngRand() c_uint {
//     // nSeed = (@as(c_uint, @bitCast(@as(c_int, 8253729))) *% nSeed) +% @as(c_uint, @bitCast(@as(c_int, 2396403)));
//     // return nSeed % @as(c_uint, @bitCast(@as(c_int, 32767)));
//     if (internalRand) |ir| {
//         const res = ir.intRangeAtMost(c_uint, 0, PRNG_MAX);
//         std.debug.print("already rand => {d}\n", .{res});
//         return res;
//     } else {
//         // Force a rando.
//         prngSrand(1);
//         const res = internalRand.?.intRangeAtMost(u32, 0, PRNG_MAX);
//         std.debug.print("rando once => {d}\n", .{res});
//         return res;
//     }
// }

// // A seed is optional, if you pass in null, you'll get a random seed.
// pub fn prngSrand(seed: ?u64) void {
//     if (seed) |s| {
//         nSeed = s;
//         var prng = std.rand.DefaultPrng.init(s);
//         internalRand = prng.random();
//     } else {
//         var prng = std.rand.DefaultPrng.init(blk: {
//             var randSeed: u64 = undefined;
//             std.posix.getrandom(std.mem.asBytes(&randSeed)) catch unreachable;
//             nSeed = randSeed;
//             break :blk randSeed;
//         });

//         internalRand = prng.random();
//     }
// }
