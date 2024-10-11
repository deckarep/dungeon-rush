const tps = @import("types.zig");
const rng = @import("prng.zig");
// int randInt(int l, int r) { return prngRand() % (r - l + 1) + l; }
// double randDouble() { return (double)prngRand() / PRNG_MAX; }

pub fn inr(x: c_int, l: c_int, r: c_int) bool {
    return x <= r and l <= x;
}

pub fn randDouble() f64 {
    return @as(f64, @floatFromInt(rng.prngRand())) / rng.PRNG_MAX;
}

pub fn distance(a: tps.Point, b: tps.Point) f64 {
    const dx = a.x - b.x;
    const dy = a.y - b.y;
    return @sqrt(dx * dx + dy * dy);
}
