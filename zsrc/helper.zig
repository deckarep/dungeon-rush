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
const spr = @import("sprite.zig");
const ren = @import("render.zig");
const gm = @import("game.zig");
const res = @import("res.zig");
const c = @import("cdefs.zig").c;

const HELPER_RECT_CROSS_LIMIT = 8;

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

pub fn IntervalCalc(l1: c_int, r1: c_int, l2: c_int, r2: c_int) c_int {
    return @max(-@max(l1, l2) + @min(r1, r2), 0);
}

pub fn RectRectCalc(a: *const c.SDL_Rect, b: *const c.SDL_Rect) c_int {
    return IntervalCalc(a.x, a.x + a.w, b.x, b.x + b.w) *
        IntervalCalc(a.y, a.y + a.h, b.y, b.y + b.h);
}

pub fn IntervalCross(l1: c_int, r1: c_int, l2: c_int, r2: c_int) bool {
    return @max(l1, l2) < @min(r1, r2);
}

pub fn RectRectCross(a: *const c.SDL_Rect, b: *const c.SDL_Rect) bool {
    return RectRectCalc(a, b) >= HELPER_RECT_CROSS_LIMIT;
    // r.c. - commented out in original.
    // return IntervalCross(a->x, a->x + a->w, b->x, b->x + b->w) &&
    //      IntervalCross(a->y, a->y + a->h, b->y, b->y + b->h);
}

pub fn RectCirCross(a: *c.SDL_Rect, x: c_int, y: c_int, r: c_int) bool {
    if (inr(x, a.x, a.x + a.w) and
        inr(y, a.y, a.y + a.h))
        return true;

    if (@abs(x - a.x) <= r) return true;

    if (@abs(x - a.x - a.w) <= r) return true;

    if (@abs(y - a.y) <= r) return true;

    if (@abs(y - a.y - a.h) <= r) return true;

    return false;
}

pub fn getSpriteAnimationBox(sprite: *spr.Sprite) c.SDL_Rect {
    const ani = sprite.ani;

    const dst: c.SDL_Rect = .{
        .x = ani.x - ani.origin.width * @divTrunc(ren.SCALE_FACTOR, 2),
        .y = ani.y - ani.origin.height * ren.SCALE_FACTOR,
        .w = ani.origin.width * ren.SCALE_FACTOR,
        .h = ani.origin.height * ren.SCALE_FACTOR,
    };

    return dst;
}

pub fn getSpriteBoundBox(sprite: *spr.Sprite) c.SDL_Rect {
    const ani = sprite.ani;

    var dst: c.SDL_Rect = .{
        .x = ani.x - ani.origin.width * @divTrunc(ren.SCALE_FACTOR, 2),
        .y = ani.y - ani.origin.height * ren.SCALE_FACTOR,
        .w = ani.origin.width * ren.SCALE_FACTOR,
        .h = ani.origin.height * ren.SCALE_FACTOR,
    };

    var big = false;
    if (ani.origin == &res.textures[res.RES_BIG_DEMON]) {
        big = true;
    } else if (ani.origin == &res.textures[res.RES_BIG_ZOMBIE]) {
        big = true;
    } else if (ani.origin == &res.textures[res.RES_ORGRE]) {
        big = true;
    }

    if (big) {
        dst.w -= gm.BIG_SPRITE_EFFECT_DELTA;
        dst.x += gm.BIG_SPRITE_EFFECT_DELTA / 2;
        dst.y += gm.SPRITE_EFFECT_VERTICAL_DELTA;
        dst.h -= gm.SPRITE_EFFECT_VERTICAL_DELTA;
    } else {
        dst.w -= gm.SPRITE_EFFECT_DELTA;
        dst.x += gm.SPRITE_EFFECT_DELTA / 2;
        dst.y += gm.SPRITE_EFFECT_VERTICAL_DELTA;
        dst.h -= gm.SPRITE_EFFECT_VERTICAL_DELTA;
    }

    return dst;
}

pub fn getSpriteFeetBox(sprite: *spr.Sprite) c.SDL_Rect {
    const ani = sprite.ani;
    var dst = getSpriteBoundBox(sprite);
    dst.y = ani.y - gm.SPRITE_EFFECT_FEET;
    dst.h = gm.SPRITE_EFFECT_FEET;
    return dst;
}

pub fn getMapRect(x: c_int, y: c_int) c.SDL_Rect {
    return c.SDL_Rect{
        .x = x * res.UNIT,
        .y = y * res.UNIT,
        .w = res.UNIT,
        .h = res.UNIT,
    };
}

pub fn distance(a: tps.Point, b: tps.Point) f64 {
    const dx: f64 = @floatFromInt(a.x - b.x);
    const dy: f64 = @floatFromInt(a.y - b.y);
    return @sqrt(dx * dx + dy * dy);
}
