const std = @import("std");
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;

const prng = @import("prng.c");

pub fn inr(x:c_int, l:c_int, r:c_int) bool { 
    return x <= r and l <= x; 
}

pub fn randInt(l:c_int, r:c_int) c_int { 
    return prng.prngRand() % (r - l + 1) + l; 
}

pub fn randDouble() f64 { 
    return prng.prngRand() / prng.prngMax;
}