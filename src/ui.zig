const std = @import("std");
const aud = @import("audio.zig");
const ren = @import("render.zig");
const res = @import("res.zig");
const hlp = @import("helper.zig");
const tps = @import("types.zig");
const pl = @import("player.zig");
const gm = @import("game.zig");
const spr = @import("sprite.zig");
const c = @import("cdefs.zig").c;

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
                    // rc: sleep added by me to give audio enough time.
                    defer std.time.sleep(std.time.ns_per_ms * 200);
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

fn chooseOptions(optionsNum: c_int, options: [*]*tps.Text) c_int {
    cursorPos = 0;
    const player = pl.createSnake(2, 0, .LOCAL);
    gm.appendSpriteToSnake(
        player,
        res.SPRITE_KNIGHT,
        res.SCREEN_WIDTH / 2,
        res.SCREEN_HEIGHT / 2,
        .UP,
    );
    const lineGap: c_int = res.FONT_SIZE + (res.FONT_SIZE >> 1);
    const totalHeight: c_int = lineGap * (optionsNum - 1);
    const startY: c_int = (res.SCREEN_HEIGHT - totalHeight) >> 1;
    while (!moveCursor(optionsNum)) {
        const sprite: *spr.Sprite = @alignCast(@ptrCast(player.sprites.head.?.element));
        sprite.ani.at = .AT_CENTER;
        sprite.x = (res.SCREEN_WIDTH >> 1) - (options[@intCast(cursorPos)].width >> 1) - (res.UNIT >> 1);
        sprite.y = startY + cursorPos * lineGap;
        ren.updateAnimationOfSprite(sprite);
        ren.renderUi();
        const optsNum: usize = @intCast(optionsNum);
        for (0..optsNum) |i| {
            const ii: c_int = @intCast(i);
            _ = ren.renderCenteredText(options[i], res.SCREEN_WIDTH >> 1, startY + ii * lineGap, 1);
        }
        // Update Screen
        c.SDL_RenderPresent(ren.renderer);
        ren.renderFrames += 1;
    }
    aud.playAudio(res.AUDIO_BUTTON1);
    gm.destroySnake(player);
    tps.destroyAnimationsByLinkList(&ren.animationsList[ren.RENDER_LIST_SPRITE_ID]);
    return cursorPos;
}

pub fn baseUi(w: c_int, h: c_int) void {
    _ = w;
    _ = h;
    ren.initRenderer();
    // initBlankMap(w, h);
    // pushMapToRender();
}

pub fn mainUi() void {
    baseUi(30, 12);
    std.log.info("about to playBgm(0)", .{});
    aud.playBgm(0);

    var startX: c_int = res.SCREEN_WIDTH / 5 + 32;
    var startY: c_int = res.SCREEN_HEIGHT / 2 - 70;

    // Title
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

    startX += UI_MAIN_GAP_ALT * (18 + 4 * @as(c_int, @intFromFloat(hlp.randDouble())));
    startY -= UI_MAIN_GAP * (1 + 3 + @as(c_int, @intFromFloat(hlp.randDouble())));

    _ = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_SPRITE_ID],
        &res.textures[res.RES_LIZARD_M],
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
    const optsNum: c_int = 4;
    const opts: [*]*tps.Text = @alignCast(@ptrCast(c.malloc(@sizeOf(*tps.Text) * optsNum)));
    for (0..optsNum) |i| {
        // r.c.: Original code is straight up pointer arithmetic.
        // offset 6 is where "Single Player" is.
        opts[i] = &res.texts[i + 6];
    }
    const opt = chooseOptions(optsNum, opts);

    // NOTE: when I move away from malloc/free this crap goes away
    // But c.free doesn't know how to deal with a Zig multi-pointer.
    // So we cast it to a an opaque.
    const freeStylePointer: ?*anyopaque = @ptrCast(opts);
    c.free(freeStylePointer);

    ren.blackout();
    ren.clearRenderer();
    // Working on chooseOptions next switch case below.
    switch (opt) {
        0 => {
            _ = c.printf("option 0 - local game!!\n");
        },
        1 => {
            _ = c.printf("option 1 - LAN game!!\n");
        },
        2 => {
            _ = c.printf("option 2 - show ranks!!\n");
        },
        else => {},
    }
    if (opt == optsNum) return;
    if (opt != 3) {
        mainUi();
    }
}
