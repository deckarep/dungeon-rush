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
const aud = @import("audio.zig");
const ren = @import("render.zig");
const res = @import("res.zig");
const hlp = @import("helper.zig");
const tps = @import("types.zig");
const pl = @import("player.zig");
const gm = @import("game.zig");
const spr = @import("sprite.zig");
const mp = @import("map.zig");
const c = @import("cdefs.zig").c;
const th = @import("throttler.zig");
const gAllocator = @import("alloc.zig").gAllocator;

const UI_MAIN_GAP = 40;
const UI_MAIN_GAP_ALT = 22;

var cursorPos: c_int = undefined;

fn moveCursor(optsNum: c_int) bool {
    var e: c.SDL_Event = undefined;
    var quit = false;

    while (c.SDL_PollEvent(&e) != 0) {
        if (e.type == c.SDL_QUIT) {
            quit = true;
            cursorPos = optsNum;
            return quit;
        } else if (e.type == c.SDL_KEYDOWN) {
            const keyValue = e.key.keysym.sym;
            switch (keyValue) {
                c.SDLK_UP => {
                    cursorPos -= 1;
                    aud.playAudio(res.AUDIO_INTER1);
                },
                c.SDLK_DOWN => {
                    cursorPos += 1;
                    aud.playAudio(res.AUDIO_INTER1);
                },
                c.SDLK_RETURN => {
                    quit = true;
                    break;
                },
                c.SDLK_ESCAPE => {
                    quit = true;
                    cursorPos = optsNum;
                    aud.playAudio(res.AUDIO_BUTTON1);
                    return quit;
                },
                else => {},
            }
        }
    }
    cursorPos += optsNum;
    cursorPos = @mod(cursorPos, optsNum);
    return quit;
}

fn chooseOptions(optionsNum: c_int, options: []const *tps.Text) c_int {
    cursorPos = 0;
    const player = pl.createSnake(2, 0, .LOCAL);
    gm.appendSpriteToSnake(
        player,
        res.SPRITE_KNIGHT,
        res.SCREEN_WIDTH / 2,
        res.SCREEN_HEIGHT / 2,
        .UP,
    );
    const lineGap: c_int = res.FONT_SIZE + res.FONT_SIZE / 2;
    const totalHeight: c_int = lineGap * (optionsNum - 1);
    const startY: c_int = @divTrunc((res.SCREEN_HEIGHT - totalHeight), 2);

    var throttler = th.Throttler.init();
    while (!moveCursor(optionsNum)) {
        if (throttler.shouldWait()) {
            continue;
        }

        const sprite: *spr.Sprite = @alignCast(@ptrCast(player.sprites.first.?.data));
        sprite.ani.at = .AT_CENTER;
        sprite.x = (res.SCREEN_WIDTH / 2) - @divTrunc(options[@intCast(cursorPos)].width, 2) - (res.UNIT / 2);
        sprite.y = startY + cursorPos * lineGap;
        ren.updateAnimationOfSprite(sprite);
        ren.renderUi();

        const optsNum: usize = @intCast(optionsNum);
        for (0..optsNum) |i| {
            const ii: c_int = @intCast(i);
            _ = ren.renderCenteredText(options[i], res.SCREEN_WIDTH / 2, startY + ii * lineGap, 1);
        }

        // Wedge in Zig-Edition
        // by @deckarep text.
        _ = ren.renderCenteredText(&res.texts[17], res.SCREEN_WIDTH / 2, 920, 1);

        // Update Screen
        c.SDL_RenderPresent(ren.renderer);
        ren.renderFrames += 1;

        throttler.tick();
    }
    aud.playAudio(res.AUDIO_BUTTON1);
    gm.destroySnake(player);
    tps.destroyAnimationsByLinkList(&ren.animationsList[ren.RENDER_LIST_SPRITE_ID]);
    return cursorPos;
}

pub fn baseUi(w: c_int, h: c_int) void {
    ren.initRenderer();
    mp.initBlankMap(w, h);
    mp.pushMapToRender();
}

fn chooseLevelUi() bool {
    baseUi(30, 12);
    const optsNum = 3;

    const opts = gAllocator.alloc(*tps.Text, @as(usize, @intCast((optsNum)))) catch unreachable;
    defer gAllocator.free(opts);

    for (0..optsNum) |i| {
        opts[i] = &res.texts[i + 10];
    }
    const opt = chooseOptions(optsNum, opts);
    if (opt != optsNum) {
        gm.setLevel(opt);
    }
    ren.clearRenderer();

    return opt != optsNum;
}

fn launchLocalGame(localPlayerNum: c_int) void {
    const scores = gm.startGame(localPlayerNum, 0, true);

    // TODO: Cleaning up score temporarily, but it's used in commented out code below which is not finished!
    defer gAllocator.free(scores);
    for (scores) |sc| {
        tps.destroyScore(sc);
    }

    //rankListUi(localPlayerNum, scores);
    //   for (int i = 0; i < localPlayerNum; i++) {
    //     updateLocalRanklist(scores[i]);
    //   }
    //   destroyRanklist(localPlayerNum, scores);
}

pub fn mainUi() void {
    baseUi(30, 12);
    aud.playBgm(0);

    var startY: c_int = (res.SCREEN_HEIGHT / 2) - 70;
    var startX: c_int = (res.SCREEN_WIDTH / 5) + 32;

    // Title - Logo
    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_UI_ID],
        &res.textures[res.RES_TITLE],
        null,
        .LOOP_INFI,
        80,
        res.SCREEN_WIDTH / 2,
        280,
        c.SDL_FLIP_NONE,
        0,
        .AT_CENTER,
    );

    // Knight
    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_SPRITE_ID],
        &res.textures[res.RES_KNIGHT_M],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        startX,
        startY,
        c.SDL_FLIP_NONE,
        0,
        .AT_BOTTOM_CENTER,
    );

    // Sword effect
    const ani = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_EFFECT_ID],
        &res.textures[res.RES_SwordFx],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        startX + UI_MAIN_GAP_ALT * 2,
        startY - 32,
        c.SDL_FLIP_NONE,
        0,
        .AT_BOTTOM_CENTER,
    );
    ani.scaled = false;

    // Red bad-guy (Knight enemy)
    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_SPRITE_ID],
        &res.textures[res.RES_CHORT],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        startX + UI_MAIN_GAP_ALT * 2,
        startY - 32,
        c.SDL_FLIP_HORIZONTAL,
        0,
        .AT_BOTTOM_CENTER,
    );

    startX += UI_MAIN_GAP_ALT * (6 + 2 * @as(c_int, @intFromFloat(hlp.randDouble())));
    startY += UI_MAIN_GAP * (1 + @as(c_int, @intFromFloat(hlp.randDouble())));

    // Green elf
    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_SPRITE_ID],
        &res.textures[res.RES_ELF_M],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        startX,
        startY,
        c.SDL_FLIP_HORIZONTAL,
        0,
        .AT_BOTTOM_CENTER,
    );
    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_EFFECT_ID],
        &res.textures[res.RES_HALO_EXPLOSION2],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        startX - @as(c_int, @intFromFloat((UI_MAIN_GAP * 1.5))),
        startY,
        c.SDL_FLIP_NONE,
        0,
        .AT_BOTTOM_CENTER,
    );
    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_SPRITE_ID],
        &res.textures[res.RES_ZOMBIE],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        startX - @as(c_int, @intFromFloat((UI_MAIN_GAP * 1.5))),
        startY,
        c.SDL_FLIP_NONE,
        0,
        .AT_BOTTOM_CENTER,
    );

    startX -= UI_MAIN_GAP_ALT * (1 + 2 * @as(c_int, @intFromFloat(hlp.randDouble())));
    startY += UI_MAIN_GAP * (2 + @as(c_int, @intFromFloat(hlp.randDouble())));

    // Blue wizard and fireball.
    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_SPRITE_ID],
        &res.textures[res.RES_WIZZARD_M],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        startX,
        startY,
        c.SDL_FLIP_NONE,
        0,
        .AT_BOTTOM_CENTER,
    );
    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_EFFECT_ID],
        &res.textures[res.RES_FIREBALL],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        startX + UI_MAIN_GAP,
        startY,
        c.SDL_FLIP_NONE,
        0,
        .AT_BOTTOM_CENTER,
    );

    startX += @intFromFloat(UI_MAIN_GAP_ALT * (18.0 + 4.0 * hlp.randDouble()));
    startY -= @intFromFloat(UI_MAIN_GAP * (1.0 + 3.0 * hlp.randDouble()));

    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_SPRITE_ID],
        &res.textures[res.RES_ZIGGY_M],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        startX,
        startY,
        c.SDL_FLIP_NONE,
        0,
        .AT_BOTTOM_CENTER,
    );
    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_EFFECT_ID],
        &res.textures[res.RES_CLAWFX2],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        startX,
        startY - UI_MAIN_GAP + 16,
        c.SDL_FLIP_NONE,
        0,
        .AT_BOTTOM_CENTER,
    );
    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_SPRITE_ID],
        &res.textures[res.RES_MUDDY],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        startX,
        startY - UI_MAIN_GAP,
        c.SDL_FLIP_HORIZONTAL,
        0,
        .AT_BOTTOM_CENTER,
    );

    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_EFFECT_ID],
        &res.textures[res.RES_CLAWFX2],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        startX + UI_MAIN_GAP,
        startY - UI_MAIN_GAP + 16,
        c.SDL_FLIP_NONE,
        0,
        .AT_BOTTOM_CENTER,
    );
    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_SPRITE_ID],
        &res.textures[res.RES_SWAMPY],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        startX + UI_MAIN_GAP,
        startY - UI_MAIN_GAP,
        c.SDL_FLIP_HORIZONTAL,
        0,
        .AT_BOTTOM_CENTER,
    );

    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_EFFECT_ID],
        &res.textures[res.RES_CLAWFX2],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        startX + UI_MAIN_GAP,
        startY + 16,
        c.SDL_FLIP_NONE,
        0,
        .AT_BOTTOM_CENTER,
    );
    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_SPRITE_ID],
        &res.textures[res.RES_SWAMPY],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        startX + UI_MAIN_GAP,
        startY,
        c.SDL_FLIP_HORIZONTAL,
        0,
        .AT_BOTTOM_CENTER,
    );

    // TODO: get rid of malloc/free crapola.
    const optsNum = 4;
    const opts = gAllocator.alloc(*tps.Text, optsNum) catch unreachable;
    for (0..optsNum) |i| {
        // r.c.: Original code is straight up pointer arithmetic.
        // offset 6 is where "Single Player" is.
        opts[i] = &res.texts[i + 6];
    }
    const opt = chooseOptions(optsNum, opts);
    gAllocator.free(opts);

    ren.blackout();
    ren.clearRenderer();
    // Working on chooseOptions next switch case below.
    switch (opt) {
        0 => {
            if (chooseLevelUi()) {
                launchLocalGame(1);
            }
            std.debug.print("option 0 - local game!!\n", .{});
        },
        1 => {
            std.debug.print("option 1 - LAN game - (NOT BUILT OUT)!!\n", .{});
        },
        2 => {
            std.debug.print("option 2 - show ranks (NOT BUILT OUT)!!\n", .{});
        },
        else => {},
    }
    if (opt == optsNum) return;
    if (opt != 3) {
        mainUi();
    }
}
