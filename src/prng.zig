pub const PRNG_MAX = 32767;
pub var nSeed: c_uint = @as(c_uint, @bitCast(@as(c_int, 5323)));

pub fn prngRand() c_uint {
    nSeed = (@as(c_uint, @bitCast(@as(c_int, 8253729))) *% nSeed) +% @as(c_uint, @bitCast(@as(c_int, 2396403)));
    return nSeed % @as(c_uint, @bitCast(@as(c_int, 32767)));
}

pub fn prngSrand(arg_seed: c_uint) void {
    var seed = arg_seed;
    _ = &seed;
    nSeed = seed;
}
