const c = @import("c_headers.zig").c;
const std = @import("std");
const assert = std.debug.assert;
const stdout = std.io.getStdOut().writer();

const helper = @import("helper.zig");
const types = @import("types.zig");
const render = @import("render.zig");

pub extern const n: c_int;
pub extern const m: c_int;

// Extern
pub extern var map: [c.MAP_SIZE][c.MAP_SIZE]c.Block;
pub extern var textures: [c.TILESET_SIZE]c.Texture;
pub extern var animationsList: [c.ANIMATION_LINK_LIST_NUM]c.LinkList;

// Extern for now...
pub extern var hasMap: [c.MAP_SIZE][c.MAP_SIZE]bool;
pub extern var isTrap: [c.MAP_SIZE][c.MAP_SIZE]bool;
pub extern var primMap: [c.MAP_SIZE][c.MAP_SIZE]bool;

pub extern var exitX: c_int;
pub extern var exitY: c_int;

pub fn clearMapGenerator() void {
    exitX = -1;
    exitY = -1;

    // Per the docs: Zig recommends this safer variant instead of memset.
    //memset(hasMap, 0, sizeof(hasMap));
    //memset(isTrap, 0, sizeof(isTrap));
    //memset(primMap, 0, sizeof(primMap));

    // This technique is also leverage comptime array multiplication for initialization.
    for (hasMap[0..c.MAP_SIZE]) |*b| b.* = [_]bool{false} ** c.MAP_SIZE;
    for (isTrap[0..c.MAP_SIZE]) |*b| b.* = [_]bool{false} ** c.MAP_SIZE;
    for (primMap[0..c.MAP_SIZE]) |*b| b.* = [_]bool{false} ** c.MAP_SIZE;
}

pub fn initBlock(self: *c.Block, bp: c.BlockType, x: c_int, y: c_int, bid: c_int, enable: bool) void {
    self.*.x = x;
    self.*.y = y;
    self.*.bp = bp;
    self.*.bid = bid;
    self.*.enable = enable;

    if (bp == c.BLOCK_TRAP) {
        const floor: usize = if (enable) c.RES_FLOOR_SPIKE_ENABLED else c.RES_FLOOR_SPIKE_DISABLED;
        self.*.ani = types.createAnimation(&textures[floor], null, c.LOOP_INFI, 1, x, y, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
    } else if (bp == c.BLOCK_EXIT) {
        const floor: usize = if (enable) c.RES_FLOOR_EXIT else c.RES_FLOOR_2;
        self.*.ani = types.createAnimation(&textures[floor], null, c.LOOP_INFI, 1, x, y, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
    } else {
        self.*.ani = types.createAnimation(&textures[@intCast(bid)], null, c.LOOP_INFI, 1, x, y, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
    }
}

pub fn initBlankMap(w: c_int, h: c_int) void {
    clearMapGenerator();

    const si: c_int = @divTrunc(n, 2) - @divTrunc(w, 2);
    const sj: c_int = @divTrunc(m, 2) - @divTrunc(h, 2);

    var i: c_int = 0;
    while (i < w) : (i += 1) {
        var j: c_int = 0;
        while (j < h) : (j += 1) {
            const ii: c_int = si + i;
            const jj: c_int = sj + j;

            hasMap[@intCast(ii)][@intCast(jj)] = @as(c_int, 1) != 0;

            const x: c_int = @intCast(ii * c.UNIT);
            const y: c_int = @intCast(jj * c.UNIT);

            initBlock(&map[@intCast(ii)][@intCast(jj)], c.BLOCK_FLOOR, x, y, c.RES_FLOOR_1, false);
        }
    }
}

// Note: in the c version these externs were defined in the function below.
extern const MAP_WALL_HOW_DECORATED: f64;
extern const MAP_HOW_OLD: f64;
pub fn pushMapToRender() void {
    var i: usize = 0;
    while (i < n) : (i += 1) {
        var j: usize = 0;
        while (j < m) : (j += 1) {
            if (!hasMap[i][j]) {
                if (helper.inr(@as(c_int, @intCast(j)) + 1, 0, @as(c_int, m) - 1) and hasMap[i][j + 1]) {
                    if (helper.inr(@as(c_int, @intCast(i)) + 1, 0, n - 1) and hasMap[i + 1][j]) {
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_ID], &textures[c.RES_WALL_CORNER_FRONT_RIGHT], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, @as(c_int, @intCast(j)) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_ID], &textures[c.RES_WALL_CORNER_BOTTOM_RIGHT], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, (@as(c_int, @intCast(j)) - 1) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                    } else if (helper.inr(@as(c_int, @intCast(i)) - 1, 0, @as(c_int, n) - 1) and hasMap[i - 1][j]) {
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_ID], &textures[c.RES_WALL_CORNER_FRONT_LEFT], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, @as(c_int, @intCast(j)) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_ID], &textures[c.RES_WALL_CORNER_BOTTOM_LEFT], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, (@as(c_int, @intCast(j)) - 1) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                    } else {
                        var bid: c_int = if (helper.randDouble() < MAP_HOW_OLD * 5) c.RES_WALL_HOLE_1 + helper.randInt(0, 1) else c.RES_WALL_MID;
                        if (helper.randDouble() < MAP_WALL_HOW_DECORATED) {
                            bid = c.RES_WALL_BANNER_RED + helper.randInt(0, 3);
                        }
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_ID], &textures[@intCast(bid)], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, @as(c_int, @intCast(j)) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_ID], &textures[c.RES_WALL_TOP_MID], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, (@as(c_int, @intCast(j)) - 1) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                    }
                }
                if (helper.inr(@as(c_int, @intCast(j)) - 1, 0, m - 1) and hasMap[i][j - 1]) {
                    const bid: c_int = if (helper.randDouble() < MAP_HOW_OLD * 2) c.RES_WALL_HOLE_1 + helper.randInt(0, 1) else c.RES_WALL_MID;
                    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_ID], &textures[@intCast(bid)], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, @as(c_int, @intCast(j)) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                    if (hasMap[i - 1][j]) {
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_FOREWALL], &textures[c.RES_WALL_CORNER_TOP_LEFT], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, (@as(c_int, @intCast(j)) - 1) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                    } else if (hasMap[i + 1][j]) {
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_FOREWALL], &textures[c.RES_WALL_CORNER_TOP_RIGHT], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, (@as(c_int, @intCast(j)) - 1) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                    } else {
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_FOREWALL], &textures[c.RES_WALL_TOP_MID], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, (@as(c_int, @intCast(j)) - 1) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                    }
                }
                if (helper.inr(@as(c_int, @intCast(i)) + 1, 0, n - 1) and hasMap[i + 1][j]) {
                    if (helper.inr(@as(c_int, @intCast(j)) + 1, 0, m - 1) and hasMap[i][j + 1]) {
                        // Do not render.
                    } else {
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_ID], &textures[c.RES_WALL_SIDE_MID_LEFT], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, @as(c_int, @intCast(j)) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                    }
                    if (!hasMap[i + 1][j + 1]) {
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_ID], &textures[c.RES_WALL_SIDE_FRONT_LEFT], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, (@as(c_int, @intCast(j)) + 1) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                    }
                    if (!hasMap[i + 1][j - 1]) {
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_ID], &textures[c.RES_WALL_SIDE_MID_LEFT], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, (@as(c_int, @intCast(j)) - 1) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_ID], &textures[c.RES_WALL_SIDE_TOP_LEFT], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, (@as(c_int, @intCast(j)) - 2) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                    }
                }
                if (helper.inr(@as(c_int, @intCast(i)) - 1, 0, n - 1) and hasMap[i - 1][j]) {
                    if (helper.inr(@as(c_int, @intCast(j)) + 1, 0, m - 1) and hasMap[i][j + 1]) {
                        // Do not render.
                    } else {
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_ID], &textures[c.RES_WALL_SIDE_MID_RIGHT], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, @as(c_int, @intCast(j)) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                    }
                    if (!hasMap[i - 1][j + 1]) {
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_ID], &textures[c.RES_WALL_SIDE_FRONT_RIGHT], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, (@as(c_int, @intCast(j)) + 1) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                    }
                    if (!hasMap[i - 1][j - 1]) {
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_ID], &textures[c.RES_WALL_SIDE_MID_RIGHT], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, (@as(c_int, @intCast(j)) - 1) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                        _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_MAP_ID], &textures[c.RES_WALL_SIDE_TOP_RIGHT], null, c.LOOP_INFI, 1, @as(c_int, @intCast(i)) * c.UNIT, (@as(c_int, @intCast(j)) - 2) * c.UNIT, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
                    }
                }
            }
        }
    }

    i = 0;
    while (i < c.SCREEN_WIDTH / c.UNIT) : (i += 1) {
        var j: usize = 0;
        while (j < c.SCREEN_HEIGHT / c.UNIT) : (j += 1) {
            if (!hasMap[i][j]) {
                continue;
            }
            const node: *c.LinkNode = c.createLinkNode(map[i][j].ani);
            //#ifdef DBG
            //     assert(node->element);
            //#endif
            types.pushLinkNode(&animationsList[c.RENDER_LIST_MAP_ID], node);
        }
    }
}
