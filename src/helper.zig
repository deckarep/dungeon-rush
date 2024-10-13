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
    const dx = a.x - b.x;
    const dy = a.y - b.y;
    return @sqrt(dx * dx + dy * dy);
}
