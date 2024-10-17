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
const c = @import("cdefs.zig").c;
const res = @import("res.zig");
const tps = @import("types.zig");
const adt = @import("adt.zig");
const spr = @import("sprite.zig");
const pl = @import("player.zig");
const gm = @import("game.zig");

pub const ANIMATION_LINK_LIST_NUM = 16;
pub const RENDER_LIST_MAP_ID = 0;
pub const RENDER_LIST_MAP_SPECIAL_ID = 1;
pub const RENDER_LIST_MAP_ITEMS_ID = 2;
pub const RENDER_LIST_DEATH_ID = 3;
pub const RENDER_LIST_SPRITE_ID = 4;
pub const RENDER_LIST_EFFECT_ID = 5;
pub const RENDER_LIST_MAP_FOREWALL = 6;
pub const RENDER_LIST_UI_ID = 7;
pub const RENDER_BUFFER_SIZE = 1 << 16;
pub const RENDER_HP_BAR_HEIGHT = 2;
pub const RENDER_HP_BAR_WIDTH = 20;
pub const RENDER_COUNTDOWN_BAR_WIDTH = 300;
pub const RENDER_COUNTDOWN_BAR_HEIGHT = 10;
pub const SPRITE_ANIMATION_DURATION = 30;
pub const RENDER_BG_COLOR: c.SDL_Color = .{ .r = 25, .g = 17, .b = 23, .a = 255 };
pub const RENDER_BLACKOUT_DURATION = 20;
pub const RENDER_DIM_DURATION = 8;
pub const RENDER_TERM_COUNT = 60;
pub const RENDER_GAMEOVER_DURATION = 1;

// UI
pub const UI_COUNTDOWN_BAR_WIDTH = 128;
pub const SCALE_FACTOR = 2;

pub var renderer: *c.SDL_Renderer = undefined;
pub var renderFrames: usize = 0;

pub var animationsList: [ANIMATION_LINK_LIST_NUM]adt.LinkList = undefined;

pub fn blacken(duration: usize) void {
    _ = c.SDL_SetRenderDrawBlendMode(renderer, c.SDL_BLENDMODE_BLEND);
    const rect: c.SDL_Rect = .{ .x = 0, .y = 0, .w = res.SCREEN_WIDTH, .h = res.SCREEN_HEIGHT };
    _ = c.SDL_SetRenderDrawColor(
        renderer,
        RENDER_BG_COLOR.r,
        RENDER_BG_COLOR.g,
        RENDER_BG_COLOR.b,
        RENDER_BG_COLOR.a,
    );

    for (0..duration) |_| {
        _ = c.SDL_RenderFillRect(renderer, &rect);
        c.SDL_RenderPresent(renderer);
    }
}

pub fn blackout() void {
    blacken(RENDER_BLACKOUT_DURATION);
}

pub fn dim() void {
    blacken(RENDER_DIM_DURATION);
}

pub fn initInfo() void {
    // TODO: shows stage and text and what not.
}

pub fn initRenderer() void {
    renderFrames = 0;
    for (0..ANIMATION_LINK_LIST_NUM) |idx| {
        tps.initLinkList(&animationsList[idx]);
    }
}

// pub fn clearInfo() void {
//   destroyText(stageText);
//   stageText = NULL;
//   destroyText(taskText);
//   taskText = NULL;
//   for (int i = 0; i < playersCount; i++) {
//     destroyText(scoresText[i]);
//     scoresText[i] = NULL;
//   }
// }

pub fn clearRenderer() void {
    for (0..ANIMATION_LINK_LIST_NUM) |i| {
        tps.destroyAnimationsByLinkList(&animationsList[i]);
    }
    _ = c.SDL_RenderClear(renderer);
}

fn renderSnakeHp(snake: *pl.Snake) void {
    var p = snake.sprites.head;
    while (p != null) : (p = p.?.nxt) {
        const sprite: *spr.Sprite = @alignCast(@ptrCast(p.?.element));

        // Skip showing HP bar when health is at 100%
        if (sprite.hp == sprite.totalHp) {
            continue;
        }

        var percent: f64 = @as(f64, @floatFromInt(sprite.hp)) / @as(f64, @floatFromInt(sprite.totalHp));
        var i: usize = 0;
        while (percent > 1e-8) {
            defer {
                i += 1;
                percent -= 1;
            }

            var r: u8 = 0;
            var g: u8 = 0;
            var b: u8 = 0;

            if (i == 0) {
                if (percent < 1) {
                    r = @intFromFloat(@min((1 - percent) * 2 * 255.0, 255.0));
                    g = @intFromFloat(@max(0, 255 - (@max(0.5 - percent, 0)) * 2.0 * 255.0));
                } else {
                    g = 255;
                }
            } else {
                r = 0;
                g = 0;
                b = 255;
            }

            _ = c.SDL_SetRenderDrawColor(renderer, r, g, b, 255);
            const width: c_int = RENDER_HP_BAR_WIDTH;
            const spriteHeight: c_int = sprite.ani.origin.height * SCALE_FACTOR;
            const bar: c.SDL_Rect = .{
                .x = sprite.x - res.UNIT / 2 + (res.UNIT - width) / 2,
                .y = sprite.y - spriteHeight - RENDER_HP_BAR_HEIGHT * (@as(c_int, @intCast(i)) + 1),
                .w = @intFromFloat(@as(f64, @floatFromInt(width)) * @min(1.0, percent)),
                .h = RENDER_HP_BAR_HEIGHT,
            };
            _ = c.SDL_RenderDrawRect(renderer, &bar);
        }
    }
}

fn renderHp() void {
    for (0..@intCast(gm.spritesCount)) |i| {
        renderSnakeHp(gm.spriteSnake[i].?);
    }
}

pub fn renderCenteredText(text: *const tps.Text, x: c_int, y: c_int, scale: f64) c.SDL_Point {
    const width: c_int = @intFromFloat(@as(f64, @floatFromInt(text.width)) * scale + 0.5);
    const height: c_int = @intFromFloat(@as(f64, @floatFromInt(text.height)) * scale + 0.5);
    const dst: c.SDL_Rect = .{
        .x = x - @divTrunc(width, 2),
        .y = y - @divTrunc(height, 2),
        .w = width,
        .h = height,
    };
    _ = c.SDL_RenderCopy(renderer, text.origin, null, &dst);
    return .{ .x = x - @divTrunc(width, 2), .y = y - @divTrunc(height, 1) };
}

pub fn setEffect(texture: *tps.Texture, ef: ?*tps.Effect) void {
    if (ef == null) return;
    const effect = ef.?;
    _ = c.SDL_SetTextureBlendMode(texture.origin, effect.mode);

    const interval: f64 = @as(f64, @floatFromInt(effect.duration)) / (@as(f64, @floatFromInt(effect.length)) - 1.0);
    var progress: f64 = @floatFromInt(effect.currentFrame);
    const stage: c_int = @intFromFloat(progress / interval);
    progress -= @as(f64, @floatFromInt(stage)) * interval;
    progress /= interval;

    const prev: c.SDL_Color = effect.keys[@intCast(stage)];
    const nxt: c.SDL_Color = effect.keys[@intCast(@min(stage + 1, effect.length - 1))];

    var mixed: c.SDL_Color = undefined;
    mixed.r = @intFromFloat(@as(f64, @floatFromInt(prev.r)) * (1.0 - progress) + @as(f64, @floatFromInt(nxt.r)) * progress);
    mixed.g = @intFromFloat(@as(f64, @floatFromInt(prev.g)) * (1.0 - progress) + @as(f64, @floatFromInt(nxt.g)) * progress);
    mixed.b = @intFromFloat(@as(f64, @floatFromInt(prev.b)) * (1.0 - progress) + @as(f64, @floatFromInt(nxt.b)) * progress);
    mixed.a = @intFromFloat(@as(f64, @floatFromInt(prev.a)) * (1.0 - progress) + @as(f64, @floatFromInt(nxt.a)) * progress);

    _ = c.SDL_SetTextureColorMod(texture.origin, mixed.r, mixed.g, mixed.b);
    _ = c.SDL_SetTextureAlphaMod(texture.origin, mixed.a);
}

fn unsetEffect(texture: *tps.Texture) void {
    _ = c.SDL_SetTextureBlendMode(texture.origin, c.SDL_BLENDMODE_BLEND);
    _ = c.SDL_SetTextureColorMod(texture.origin, 255, 255, 255);
    _ = c.SDL_SetTextureAlphaMod(texture.origin, 255);
}

pub fn updateAnimationOfSprite(self: *spr.Sprite) void {
    const ani = self.ani;
    ani.x = self.x;
    ani.y = self.y;
    ani.flip = if (self.face == .RIGHT) c.SDL_FLIP_NONE else c.SDL_FLIP_HORIZONTAL;
}

pub fn updateAnimationOfSnake(snake: *pl.Snake) void {
    var p = snake.sprites.head;
    while (p != null) : (p = p.?.nxt) {
        updateAnimationOfSprite(@alignCast(@ptrCast(p.?.element)));
    }
}

pub fn updateAnimationOfBlock(self: *tps.Block) void {
    const ani = self.ani;
    ani.x = self.x;
    ani.y = self.y;

    if (self.bp == .BLOCK_TRAP) {
        self.ani.origin = &res.textures[
            if (self.enable) res.RES_FLOOR_SPIKE_ENABLED else res.RES_FLOOR_SPIKE_DISABLED
        ];
    } else if (self.bp == .BLOCK_EXIT) {
        if (self.enable and self.ani.origin != &res.textures[res.RES_FLOOR_EXIT]) {
            self.ani.origin = &res.textures[res.RES_FLOOR_EXIT];
            _ = createAndPushAnimation(
                &animationsList[RENDER_LIST_MAP_SPECIAL_ID],
                &res.textures[res.RES_FLOOR_EXIT],
                &res.effects[res.EFFECT_BLINK],
                .LOOP_INFI,
                30,
                self.x,
                self.y,
                c.SDL_FLIP_NONE,
                0,
                .AT_TOP_LEFT,
            );
        }
    }
}

pub fn clearBindInAnimationsList(sprite: *spr.Sprite, id: c_int) void {
    var p = animationsList[@intCast(id)].head;
    var nxt: ?*adt.LinkNode = null;
    while (p != null) : (p = nxt) {
        nxt = p.?.nxt;
        const ani: *tps.Animation = @alignCast(@ptrCast(p.?.element));
        if (ani.bind != null and ani.bind.? == @as(*anyopaque, sprite)) {
            ani.bind = null;
            if (ani.dieWithBind) {
                tps.removeLinkNode(&animationsList[@intCast(id)], p.?);
                tps.destroyAnimation(ani);
            }
        }
    }
}

pub fn bindAnimationToSprite(ani: *tps.Animation, sprite: *spr.Sprite, isStrong: bool) void {
    ani.bind = sprite;
    ani.dieWithBind = isStrong;
    updateAnimationFromBind(ani);
}

pub fn updateAnimationFromBind(ani: *tps.Animation) void {
    if (ani.bind) |bnd| {
        const sprite: *spr.Sprite = @alignCast(@ptrCast(bnd));
        ani.x = sprite.x;
        ani.y = sprite.y;
        ani.flip = sprite.ani.flip;
    }
}

pub fn renderAnimation(a: ?*tps.Animation) void {
    if (a == null) return;
    const ani = a.?;

    updateAnimationFromBind(ani);
    var width = ani.origin.width;
    var height = ani.origin.height;
    var poi: c.SDL_Point = .{
        .x = ani.origin.width,
        .y = @divTrunc(ani.origin.height, 2),
    };

    if (ani.scaled) {
        width *= SCALE_FACTOR;
        height *= SCALE_FACTOR;
    }

    var dst = c.SDL_Rect{
        .x = ani.x - @divTrunc(width, 2),
        .y = ani.y - height,
        .w = width,
        .h = height,
    };

    if (ani.at == .AT_TOP_LEFT) {
        dst.x = ani.x;
        dst.y = ani.y;
    } else if (ani.at == .AT_CENTER) {
        dst.x = ani.x - @divTrunc(width, 2);
        dst.y = ani.y - @divTrunc(height, 2);
        poi.x = @divTrunc(ani.origin.width, 2);
    } else if (ani.at == .AT_BOTTOM_LEFT) {
        dst.x = ani.x;
        dst.y = ani.y + res.UNIT - height - 3;
    }
    if (ani.effect) |ef| {
        setEffect(ani.origin, ef);
        ef.currentFrame = @mod(ef.currentFrame, ef.duration);
    }
    // #ifdef DBG
    //   assert(ani->duration >= ani->origin->frames);
    // #endif

    // rc: stage just means which animation frame.
    var stage: usize = 0;
    if (ani.origin.frames > 1) {
        const interval: f64 = @as(f64, @floatFromInt(ani.duration)) / @as(f64, @floatFromInt(ani.origin.frames));
        stage = @intFromFloat(@floor(@as(f64, @floatFromInt(ani.currentFrame)) / interval));
    }
    _ = c.SDL_RenderCopyEx(
        renderer,
        ani.origin.origin,
        &(ani.origin.crops[stage]),
        &dst,
        ani.angle,
        &poi,
        ani.flip,
    );
    if (ani.effect) |_| {
        unsetEffect(ani.origin);
    }
    // #ifdef DBG_CROSS
    //   if (ani->at == AT_BOTTOM_CENTER) {
    //     Sprite fake;
    //     fake.ani = ani;
    //     SDL_Rect tmp;

    //     tmp = getSpriteBoundBox(&fake);
    //     SDL_SetRenderDrawColor(renderer, 0, 255, 0, 200);
    //     SDL_RenderDrawRect(renderer, &tmp);

    //     tmp = getSpriteFeetBox(&fake);
    //     SDL_SetRenderDrawColor(renderer, 255, 0, 0, 200);
    //     SDL_RenderDrawRect(renderer, &tmp);

    //     SDL_SetRenderDrawColor(renderer, 0, 0, 255, 200);
    //     SDL_RenderDrawRect(renderer, &dst);
    //   }
    // #endif
}

pub fn pushAnimationToRender(id: c_int, ani: *tps.Animation) void {
    const p = tps.createLinkNode(ani);
    tps.pushLinkNode(&animationsList[@intCast(id)], p);
}

pub fn createAndPushAnimation(
    list: *adt.LinkList,
    texture: *tps.Texture,
    effect: ?*const tps.Effect,
    lp: tps.LoopType,
    duration: c_int,
    x: c_int,
    y: c_int,
    flip: c.SDL_RendererFlip,
    angle: f64,
    at: tps.At,
) *tps.Animation {
    const ani = tps.createAnimation(
        texture,
        effect,
        lp,
        duration,
        x,
        y,
        flip,
        angle,
        at,
    );
    const node = tps.createLinkNode(ani);
    tps.pushLinkNode(list, node);
    return ani;
}

fn updateAnimationLinkList(list: *adt.LinkList) void {
    var p = list.head;
    while (p != null) {
        const ptr = p.?;
        // r.c. going to make that we always have an animation in within the linked list.
        const ani: *tps.Animation = @alignCast(@ptrCast(ptr.element.?));
        const nxt = ptr.nxt;
        ani.currentFrame += 1;
        ani.lifeSpan -= 1;

        if (ani.effect) |eff| {
            eff.currentFrame += 1;
            eff.currentFrame = @mod(eff.currentFrame, eff.duration);
        }

        if (ani.lp == .LOOP_ONCE) {
            if (ani.currentFrame == ani.duration) {
                tps.destroyAnimation(ani);
                tps.removeLinkNode(list, ptr);
            }
        } else {
            if (ani.lp == .LOOP_LIFESPAN and ani.lifeSpan <= 0) {
                tps.destroyAnimation(ani);
                tps.removeLinkNode(list, ptr);
            } else {
                ani.currentFrame = @mod(ani.currentFrame, ani.duration);
            }
        }
        p = nxt;
    }
}

pub fn renderAnimationLinkList(list: *adt.LinkList) void {
    var p = list.head;
    while (p != null) {
        const ptr = p.?;
        renderAnimation(@alignCast(@ptrCast(ptr.element)));
        p = ptr.nxt;
    }
}

// NOTE: currently this is the only callconv(.C) cause I'm still using qsort.
// TODO: Migrate to Zig's sorting facility at some pointer.
fn compareAnimationByY(x: ?*const anyopaque, y: ?*const anyopaque) callconv(.C) c_int {
    // NOTE: r.c. - this gives a pointer to a pointer.
    const a: *const *tps.Animation = @alignCast(@ptrCast(x));
    const b: *const *tps.Animation = @alignCast(@ptrCast(y));
    //std.log.info("doing compare: b.y:{d} - a.y:{d} = {d}", .{ b.*.y, a.*.y, b.*.y - a.*.y });
    return b.*.y - a.*.y;
}

fn renderAnimationLinkListWithSort(list: *adt.LinkList) void {
    // 1. Ported C static array to Zig's static array.
    // const S = struct {
    //     var buffer: [RENDER_BUFFER_SIZE]*tps.Animation = undefined;
    // };

    // 2. After thinking it through, no need for buffer to be static.
    var buffer: [RENDER_BUFFER_SIZE]*tps.Animation = undefined;

    var count: usize = 0;
    var p = list.head;
    while (p != null) : (p = p.?.nxt) {
        buffer[count] = @alignCast(@ptrCast(p.?.element));
        count += 1;
    }

    // TODO: Swap c.qsort in favor of Zig's sorting mechanics.
    c.qsort(@ptrCast(&buffer), @intCast(count), @sizeOf(*tps.Animation), compareAnimationByY);

    // This iteration verified y are in descending order.
    // for (0..count) |i| {
    //     std.log.info("y=>{d}", .{S.buffer[i].y});
    // }

    while (count > 0) {
        count -= 1;
        renderAnimation(buffer[count]);
    }
}

pub fn render() void {
    _ = c.SDL_SetRenderDrawColor(renderer, 25, 17, 23, 255);
    _ = c.SDL_RenderClear(renderer);

    for (0..ANIMATION_LINK_LIST_NUM) |i| {
        updateAnimationLinkList(&animationsList[i]);
        if (i == RENDER_LIST_SPRITE_ID) {
            renderAnimationLinkListWithSort(&animationsList[i]);
        } else {
            renderAnimationLinkList(&animationsList[i]);
        }
    }
    // TODO: these funcs below.
    renderHp();
    //renderCountDown();
    //renderInfo();
    //renderId();
    // Update Screen
    c.SDL_RenderPresent(renderer);
    renderFrames += 1;
}

pub fn renderUi() void {
    _ = c.SDL_SetRenderDrawColor(
        renderer,
        RENDER_BG_COLOR.r,
        RENDER_BG_COLOR.g,
        RENDER_BG_COLOR.b,
        RENDER_BG_COLOR.a,
    );
    _ = c.SDL_RenderClear(renderer);

    for (0..ANIMATION_LINK_LIST_NUM) |i| {
        updateAnimationLinkList(&animationsList[i]);
        if (i == RENDER_LIST_SPRITE_ID) {
            renderAnimationLinkListWithSort(&animationsList[i]);
        } else {
            renderAnimationLinkList(&animationsList[i]);
        }
    }
}
