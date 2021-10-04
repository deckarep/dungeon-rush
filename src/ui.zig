const std = @import("std");
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;

const render = @import("render.zig");
const map = @import("map.zig");
const audio = @import("audio.zig");

pub extern var texts: [c.TEXTSET_SIZE]c.Text;
pub extern var textures: [c.TILESET_SIZE]c.Texture;
pub extern var animationsList: [c.ANIMATION_LINK_LIST_NUM]c.LinkList;

fn baseUi(w:c_int, h:c_int) void {
    render.initRenderer();
    map.initBlankMap(w, h);
    map.pushMapToRender();
}

pub fn mainUi() !void {
    try stdout.print("mainUi invoked!\n", .{});

    baseUi(30, 12);
    audio.playBgm(0);

    try stdout.print("ll type: {s}\n", .{@TypeOf(&animationsList[c.RENDER_LIST_UI_ID])});
    try stdout.print("texture type: {s}\n", .{@TypeOf(&textures[c.RES_TITLE])});

    var startY: c_int = c.SCREEN_HEIGHT / 2 - 70;
    var startX: c_int = c.SCREEN_WIDTH / 5 + 32;

    // These createAndPushAnimations create the animation intro sprites when selecting a setting. (intro screen)
    _ = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_UI_ID], &textures[c.RES_TITLE], null, c.LOOP_INFI, 80, c.SCREEN_WIDTH / 2, 280, c.SDL_FLIP_NONE, 0, c.AT_CENTER);
    _ = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_KNIGHT_M], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX, startY, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    var a = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_EFFECT_ID], &textures[c.RES_SwordFx], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX + c.UI_MAIN_GAP_ALT * 2, startY - 32, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    a.*.scaled = false;
    _ = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_CHORT], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX + c.UI_MAIN_GAP_ALT * 2, startY - 32, c.SDL_FLIP_HORIZONTAL, 0, c.AT_BOTTOM_CENTER);

    startX += c.UI_MAIN_GAP_ALT * (6 + 2 * @floatToInt(c_int, c.randDouble()));
    startY += c.UI_MAIN_GAP * (1 + @floatToInt(c_int, c.randDouble()));
    _ = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_ELF_M], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX, startY, c.SDL_FLIP_HORIZONTAL, 0, c.AT_BOTTOM_CENTER);
    _ = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_EFFECT_ID], &textures[c.RES_HALO_EXPLOSION2], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, @floatToInt(c_int, @intToFloat(f64, startX) - @intToFloat(f64, c.UI_MAIN_GAP) * 1.5), startY, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    _ = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_ZOMBIE], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, @floatToInt(c_int, @intToFloat(f64, startX) - @intToFloat(f64, c.UI_MAIN_GAP) * 1.5), startY, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);

    startX -= @floatToInt(c_int, @intToFloat(f64, c.UI_MAIN_GAP_ALT) * (1.0 + 2.0 * c.randDouble()));
    startY += @floatToInt(c_int, @intToFloat(f64, c.UI_MAIN_GAP) * (2.0 + c.randDouble()));
    _ = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_WIZZARD_M], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX, startY, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    _ = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_EFFECT_ID], &textures[c.RES_FIREBALL], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX + c.UI_MAIN_GAP, startY, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);

    startX += @floatToInt(c_int, @intToFloat(f64, c.UI_MAIN_GAP_ALT) * (18.0 + 4.0 * c.randDouble()));
    startY -= @floatToInt(c_int, @intToFloat(f64, c.UI_MAIN_GAP) * (1.0 + 3.0 * c.randDouble()));
    _ = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_LIZARD_M], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX, startY, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    _ = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_EFFECT_ID], &textures[c.RES_CLAWFX2], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX, startY - c.UI_MAIN_GAP + 16, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    _ = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_MUDDY], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX, startY - c.UI_MAIN_GAP, c.SDL_FLIP_HORIZONTAL, 0, c.AT_BOTTOM_CENTER);

    _ = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_EFFECT_ID], &textures[c.RES_CLAWFX2], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX + c.UI_MAIN_GAP, startY - c.UI_MAIN_GAP + 16, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    _ = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_SWAMPY], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX + c.UI_MAIN_GAP, startY - c.UI_MAIN_GAP, c.SDL_FLIP_HORIZONTAL, 0, c.AT_BOTTOM_CENTER);

    _ = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_EFFECT_ID], &textures[c.RES_CLAWFX2], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX + c.UI_MAIN_GAP, startY + 16, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    _ = c.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_SWAMPY], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX + c.UI_MAIN_GAP, startY, c.SDL_FLIP_HORIZONTAL, 0, c.AT_BOTTOM_CENTER);

    // commented out block in original source is here too.

    const optsNum: c_int = 4;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    const bytes = try allocator.alloc([*c]c.Text, optsNum);
    var i: usize = 0;
    while (i < optsNum) : (i += 1) {
        bytes[i] = &texts[i + 6];
    }

    const opt: c_int = c.chooseOptions(optsNum, &bytes[0]);
    try stdout.print("you chose {d}", .{opt});

    render.blackout();
    render.clearRenderer();

    var lan: c_int = 0;
    switch (opt) {
        0 => {
            if (!c.chooseLevelUi()) {
                //break;
            }
            c.launchLocalGame(1);
            //break;
        },
        1 => {
            lan = c.chooseOnLanUi();
            if (lan == 0) {
                if (!c.chooseLevelUi()) {
                    //break;
                }
                c.launchLocalGame(2);
            } else if (lan == 1) {
                c.launchLanGame();
            }
            //break;
        },
        2 => {
            c.localRankListUi();
            //break;
        },
        3 => {
            //break;

        },
        else => {
            try stdout.print("fell into else case!", .{});
        },
    }

    if (opt == optsNum) {
        return;
    }

    if (opt != 3) {
        return mainUi();
    }
}
