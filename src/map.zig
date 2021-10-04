const c = @import("c_headers.zig").c;
const assert = @import("std").debug.assert;

pub extern const n: c_int;
pub extern const m: c_int;

// Extern
pub extern var map: [c.MAP_SIZE][c.MAP_SIZE]c.Block;

// Extern for now...
pub extern var hasMap: [c.MAP_SIZE][c.MAP_SIZE]bool;

pub fn initBlankMap(w: c_int, h: c_int) void {
    c.clearMapGenerator();

    var si: c_int = @divTrunc(n, 2) - @divTrunc(w, 2);
    var sj: c_int = @divTrunc(m, 2) - @divTrunc(h, 2);

    var i: c_int = 0;
    while (i < w) : (i += 1) {
        var j: c_int = 0;
        while (j < h) : (j += 1) {
            var ii: c_int = si + i;
            var jj: c_int = sj + j;

            hasMap[@intCast(c_uint, ii)][@intCast(c_uint, jj)] = @as(c_int, 1) != 0;

            const x: c_int = @intCast(c_int, ii * c.UNIT);
            const y: c_int = @intCast(c_int, jj * c.UNIT);

            c.initBlock(&map[@intCast(usize, ii)][@intCast(usize, jj)], c.BLOCK_FLOOR, x, y, c.RES_FLOOR_1, false);
        }
    }
}

pub fn pushMapToRender() void {
    // TODO: port this function.
    c.pushMapToRender();
}
