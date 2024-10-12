const std = @import("std");
const hlp = @import("helper.zig");
const res = @import("res.zig");
const tps = @import("types.zig");
const gm = @import("game.zig");
const ren = @import("render.zig");

const c = @import("cdefs.zig").c;

pub const MAP_SIZE = 100;
pub const MAP_BLOOD_SPILL_RANGE = 20;
pub const MAP_SKULL_SPILL_RANGE = 6;

const MAP_HOW_OLD = 0.05;
// this will take effect in pushMaptoRender in game.c
const MAP_WALL_HOW_DECORATED = 0.1;

var isTrap: [MAP_SIZE][MAP_SIZE]bool = undefined;
var primMap: [MAP_SIZE][MAP_SIZE]bool = undefined;
var hasMap: [MAP_SIZE][MAP_SIZE]bool = undefined;

var exitX: c_int = undefined;
var exitY: c_int = undefined;

pub fn clearMapGenerator() void {
    exitX = -1;
    exitY = -1;

    isTrap = std.mem.zeroes([MAP_SIZE][MAP_SIZE]bool);
    primMap = std.mem.zeroes([MAP_SIZE][MAP_SIZE]bool);
    hasMap = std.mem.zeroes([MAP_SIZE][MAP_SIZE]bool);
}

fn count(x: c_int, y: c_int) c_int {
    var ret: c_int = 0;

    var dx: c_int = -1;
    var dy: c_int = -1;
    while (dx <= 1) : (dx += 1) {
        while (dy <= 1) : (dy += 1) {
            if (dx > 0 or dy > 0) {
                const xx: c_int = x + dx;
                const yy = y + dy;
                if (hlp.inr(xx, 0, res.n - 1) and hlp.inr(yy, 0, res.m - 1)) {
                    ret += primMap[xx][yy];
                }
            }
        }
    }
    return ret;
}

fn cellularAutomata() void {
    // In Zig, simulate statically declared array
    // using a container.
    const S = struct {
        var tmp: [MAP_SIZE][MAP_SIZE]bool = undefined;
    };

    for (0..res.n) |i| {
        for (0..res.m) |j| {
            const ii: c_int = @intCast(i);
            const jj: c_int = @intCast(j);
            const cc = count(ii, jj);
            if (cc <= 3) {
                S.tmp[i][j] = 0;
            } else if (cc >= 6) {
                S.tmp[i][j] = 1;
            } else {
                S.tmp[i][j] = primMap[i][j];
            }
        }
    }

    @memcpy(primMap[0..], S.tmp[0..]);
}

// DBG print methods.
// fn printMap() void {}
// fn phasMap() void {}

fn initPrimMap(floorPercent: f64, smoothTimes: c_int) void {
    _ = floorPercent;
    _ = smoothTimes;
}

fn initBlock(
    self: *tps.Block,
    bp: tps.BlockType,
    x: c_int,
    y: c_int,
    bid: c_int,
    enable: bool,
) void {
    self.x = x;
    self.y = y;
    self.bp = bp;
    self.bid = bid;
    self.enable = enable;

    if (bp == .BLOCK_TRAP) {
        self.ani = tps.createAnimation(
            &res.textures[if (enable) res.RES_FLOOR_SPIKE_ENABLED else res.RES_FLOOR_SPIKE_DISABLED],
            null,
            .LOOP_INFI,
            1,
            x,
            y,
            c.SDL_FLIP_NONE,
            0,
            .AT_TOP_LEFT,
        );
    } else if (bp == .BLOCK_EXIT) {
        self.ani = tps.createAnimation(
            &res.textures[if (enable) res.RES_FLOOR_EXIT else res.RES_FLOOR_2],
            null,
            .LOOP_INFI,
            1,
            x,
            y,
            c.SDL_FLIP_NONE,
            0,
            .AT_TOP_LEFT,
        );
    } else {
        self.ani = tps.createAnimation(
            &res.textures[@intCast(bid)],
            null,
            .LOOP_INFI,
            1,
            x,
            y,
            c.SDL_FLIP_NONE,
            0,
            .AT_TOP_LEFT,
        );
    }
}

fn initMap() void {
    // this will actually generate the map for game
    for (0..res.n) |i| {
        for (0..res.m) |j| {
            const ii: c_int = @intCast(i);
            const jj: c_int = @intCast(j);
            if ((ii != exitX or jj != exitY) and hasMap[i][j]) {
                if (isTrap[i][j]) {
                    initBlock(
                        &gm.map[i][j],
                        .BLOCK_TRAP,
                        ii * res.UNIT,
                        jj * res.UNIT,
                        // textureID does not matter
                        res.RES_FLOOR_SPIKE_DISABLED,
                        false,
                    );
                } else {
                    initBlock(
                        &gm.map[i][j],
                        .BLOCK_FLOOR,
                        ii * res.UNIT,
                        jj * res.UNIT,
                        res.RES_FLOOR_1,
                        true,
                    );
                }
            }
        }
    }
}

fn decorateMap() void {
    var i: c_int = 0;
    const lim: c_int = res.n * res.m * MAP_HOW_OLD;
    var x: usize = 0;
    var y: usize = 0;

    while (i < lim) : (i += 1) { // Original out for loop.
        while (true) {
            x = @intCast(hlp.randInt(0, res.n - 2));
            y = @intCast(hlp.randInt(0, res.m - 2));

            const condition = (hasMap[x][y] and !isTrap[x][y]) +
                (hasMap[x + 1][y] and !isTrap[x + 1][y]) +
                (hasMap[x][y + 1] and !isTrap[x][y + 1]) +
                (hasMap[x + 1][y + 1] and !isTrap[x + 1][y + 1]) < 4;

            // Since we ported a do-while loop, we negate the condition.
            if (!condition) break;
        }

        if (hlp.randDouble() < MAP_HOW_OLD) {
            gm.map[x][y].ani.origin = &res.textures[res.RES_FLOOR_6];
            gm.map[x + 1][y].ani.origin = &res.textures[res.RES_FLOOR_4];
            gm.map[x + 1][y + 1].ani.origin = &res.textures[res.RES_FLOOR_8];
            gm.map[x][y + 1].ani.origin = &res.textures[res.RES_FLOOR_7];
        } else {
            gm.map[x][y].ani.origin = &res.textures[res.RES_FLOOR_2];
            gm.map[x][y + 1].ani.origin = &res.textures[res.RES_FLOOR_5];
            gm.map[x + 1][y].ani.origin = &res.textures[res.RES_FLOOR_3];
        }
    }
}

pub fn initBlankMap(w: c_int, h: c_int) void {
    clearMapGenerator();
    const si: c_int = @divTrunc(res.n, 2) - @divTrunc(w, 2);
    const sj: c_int = @divTrunc(res.m, 2) - @divTrunc(h, 2);
    for (0..@intCast(w)) |i| {
        for (0..@intCast(h)) |j| {
            const ii = si + @as(c_int, @intCast(i));
            const jj = sj + @as(c_int, @intCast(j));
            hasMap[@intCast(ii)][@intCast(jj)] = true;
            initBlock(
                &gm.map[@intCast(ii)][@intCast(jj)],
                .BLOCK_FLOOR,
                ii * res.UNIT,
                jj * res.UNIT,
                res.RES_FLOOR_1,
                false,
            );
        }
    }
}

fn initRandomMap(floorPercent: f64, smoothTimes: c_int, trapRate: f64) void {
    _ = floorPercent;
    _ = smoothTimes;
    _ = trapRate;
}

pub fn pushMapToRender() void {
    // BUG: map isn't centered.
    // CHECK: map is the correct dimensions.
    // BIG FAT TODO: I'm not sure I ported over the if/else if/else nesting properly...fuck c for having optional curly braces.

    // Aliases to cutdown on long names.
    const cpa = ren.createAndPushAnimation;

    for (0..res.n) |i| {
        for (0..res.m) |j| {
            const i_cInt: c_int = @intCast(i);
            const j_cInt: c_int = @intCast(j);
            if (!hasMap[i][j]) {
                if (hlp.inr(j_cInt + 1, 0, res.m - 1) and hasMap[i][j + 1]) {
                    if (hlp.inr(i_cInt + 1, 0, res.n - 1) and hasMap[i + 1][j]) {
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_ID],
                            &res.textures[res.RES_WALL_CORNER_FRONT_RIGHT],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            j_cInt * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_ID],
                            &res.textures[res.RES_WALL_CORNER_BOTTOM_RIGHT],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            (j_cInt - 1) * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                    } else if (hlp.inr(i_cInt - 1, 0, res.n - 1) and hasMap[i - 1][j]) {
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_ID],
                            &res.textures[res.RES_WALL_CORNER_FRONT_LEFT],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            j_cInt * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_ID],
                            &res.textures[res.RES_WALL_CORNER_BOTTOM_LEFT],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            (j_cInt - 1) * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                    } else {
                        // Randomness for flags or holes.
                        var bid = if (hlp.randDouble() < MAP_HOW_OLD * 5) res.RES_WALL_HOLE_1 + hlp.randInt(0, 1) else res.RES_WALL_MID;
                        if (hlp.randDouble() < MAP_WALL_HOW_DECORATED) {
                            bid = res.RES_WALL_BANNER_RED + hlp.randInt(0, 3);
                        }
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_ID],
                            &res.textures[@intCast(bid)],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            j_cInt * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_ID],
                            &res.textures[res.RES_WALL_TOP_MID],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            (j_cInt - 1) * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                    }
                }
                if (hlp.inr(j_cInt - 1, 0, res.m - 1) and hasMap[i][j - 1]) {
                    const bid = if (hlp.randDouble() < MAP_HOW_OLD * 2) res.RES_WALL_HOLE_1 + hlp.randInt(0, 1) else res.RES_WALL_MID;
                    _ = cpa(
                        &ren.animationsList[ren.RENDER_LIST_MAP_ID],
                        &res.textures[@intCast(bid)],
                        null,
                        .LOOP_INFI,
                        1,
                        i_cInt * res.UNIT,
                        j_cInt * res.UNIT,
                        c.SDL_FLIP_NONE,
                        0,
                        .AT_TOP_LEFT,
                    );
                    if (hasMap[i - 1][j]) {
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_FOREWALL],
                            &res.textures[res.RES_WALL_CORNER_TOP_LEFT],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            (j_cInt - 1) * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                    } else if (hasMap[i + 1][j]) {
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_FOREWALL],
                            &res.textures[res.RES_WALL_CORNER_TOP_RIGHT],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            (j_cInt - 1) * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                    } else {
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_FOREWALL],
                            &res.textures[res.RES_WALL_TOP_MID],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            (j_cInt - 1) * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                    }
                }
                if (hlp.inr(i_cInt + 1, 0, res.n - 1) and hasMap[i + 1][j]) {
                    if (hlp.inr(j_cInt + 1, 0, res.m - 1) and hasMap[i][j + 1]) {
                        // just do not render
                    } else {
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_ID],
                            &res.textures[res.RES_WALL_SIDE_MID_LEFT],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            j_cInt * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                    }
                    if (!hasMap[i + 1][j + 1]) {
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_ID],
                            &res.textures[res.RES_WALL_SIDE_FRONT_LEFT],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            (j_cInt + 1) * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                    }
                    if (!hasMap[i + 1][j - 1]) {
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_ID],
                            &res.textures[res.RES_WALL_SIDE_MID_LEFT],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            (j_cInt - 1) * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_ID],
                            &res.textures[res.RES_WALL_SIDE_TOP_LEFT],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            (j_cInt - 2) * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                    }
                }
                if (hlp.inr(i_cInt - 1, 0, res.n - 1) and hasMap[i - 1][j]) {
                    if (hlp.inr(j_cInt + 1, 0, res.m - 1) and hasMap[i][j + 1]) {
                        // just do not render
                    } else {
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_ID],
                            &res.textures[res.RES_WALL_SIDE_MID_RIGHT],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            j_cInt * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                    }
                    if (!hasMap[i - 1][j + 1]) {
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_ID],
                            &res.textures[res.RES_WALL_SIDE_FRONT_RIGHT],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            (j_cInt + 1) * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                    }
                    if (!hasMap[i - 1][j - 1]) {
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_ID],
                            &res.textures[res.RES_WALL_SIDE_MID_RIGHT],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            (j_cInt - 1) * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                        _ = cpa(
                            &ren.animationsList[ren.RENDER_LIST_MAP_ID],
                            &res.textures[res.RES_WALL_SIDE_TOP_RIGHT],
                            null,
                            .LOOP_INFI,
                            1,
                            i_cInt * res.UNIT,
                            (j_cInt - 2) * res.UNIT,
                            c.SDL_FLIP_NONE,
                            0,
                            .AT_TOP_LEFT,
                        );
                    }
                }
            }
        }
    }

    for (0..(res.SCREEN_WIDTH / res.UNIT)) |i| {
        for (0..(res.SCREEN_HEIGHT / res.UNIT)) |j| {
            if (!hasMap[i][j]) {
                continue;
            }
            const node = tps.createLinkNode(gm.map[i][j].ani);
            std.debug.assert(node.element != null);
            tps.pushLinkNode(&ren.animationsList[ren.RENDER_LIST_MAP_ID], node);
        }
    }
}
