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

const tps = @import("types.zig");
const rng = @import("prng.zig");

pub inline fn inr(val: c_int, lower: c_int, upper: c_int) bool {
    return lower <= val and val <= upper;
}

pub fn randInt(l: c_int, r: c_int) c_int {
    const rdm: c_int = @intCast(rng.prngRand());
    return @mod(rdm, (r - l + 1) + l);
}

pub fn randDouble() f64 {
    return @as(f64, @floatFromInt(rng.prngRand())) / rng.PRNG_MAX;
}

pub fn distance(a: tps.Point, b: tps.Point) f64 {
    const dx: f64 = @floatFromInt(a.x - b.x);
    const dy: f64 = @floatFromInt(a.y - b.y);
    return @sqrt(dx * dx + dy * dy);
}
