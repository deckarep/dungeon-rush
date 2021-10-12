const std = @import("std");
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;

const render = @import("render.zig");
const map = @import("map.zig");
const audio = @import("audio.zig");
const storage = @import("storage.zig");
const types = @import("types.zig");
const game = @import("game.zig");

pub extern var texts: [c.TEXTSET_SIZE]c.Text;
pub extern var textures: [c.TILESET_SIZE]c.Texture;
pub extern var animationsList: [c.ANIMATION_LINK_LIST_NUM]c.LinkList;
pub extern const WHITE: c.SDL_Color;
pub extern var renderer: *c.SDL_Renderer;
pub extern var renderFrames: c_int;

// Extern for now.
pub extern var cursorPos: c_int;

fn baseUi(w: c_int, h: c_int) void {
    render.initRenderer();
    map.initBlankMap(w, h);
    map.pushMapToRender();
}

pub fn chooseLevelUi() !bool {
    baseUi(30, 12);
    const optsNum: c_int = 3;

    // TODO: consolidate allocators.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    const bytes = try allocator.alloc([*c]c.Text, optsNum);
    var i: usize = 0;
    while (i < optsNum) : (i += 1) {
        bytes[i] = &texts[i + 10];
    }

    const opt: c_int = chooseOptions(optsNum, &bytes[0]);
    if (opt != optsNum) {
        game.setLevel(opt);
    }
    render.clearRenderer();
    return opt != optsNum;
}

pub fn launchLocalGame(localPlayerNum: c_int) !void {
    const scores = c.startGame(localPlayerNum, 0, true);

    try rankListUi(localPlayerNum, scores);
    var i: usize = 0;
    while (i < localPlayerNum) : (i += 1) {
        storage.updateLocalRanklist(scores[i]);
    }
    storage.destroyRanklist(localPlayerNum, scores);
}

pub fn chooseOptions(optionsNum: c_int, options: [*c][*c]c.Text) c_int {
    cursorPos = 0;

    var player: *c.Snake = c.createSnake(2, 0, c.LOCAL);
    c.appendSpriteToSnake(player, c.SPRITE_KNIGHT, c.SCREEN_WIDTH / 2, c.SCREEN_HEIGHT / 2, c.UP);

    const lineGap: c_int = c.FONT_SIZE + c.FONT_SIZE / 2;
    const totalHeight = lineGap * (optionsNum - 1);
    const startY = @divTrunc(c.SCREEN_HEIGHT - totalHeight, 2);

    while (!c.moveCursor(optionsNum)) {
        // Note: Zig won't cast implicitly from a ?*c_void' pointer.
        // We pull out the element and cast to an Sprite type.
        var sprite: *c.Sprite = @ptrCast([*c]c.Sprite, @alignCast(@import("std").meta.alignment([*c]c.Sprite), player.*.sprites.*.head.*.element));
        sprite.*.ani.*.at = c.AT_CENTER;
        sprite.*.x = c.SCREEN_WIDTH / 2 - @divTrunc(options[@intCast(usize, cursorPos)].*.width, 2) - c.UNIT / 2;
        sprite.*.y = startY + cursorPos * lineGap;
        render.updateAnimationOfSprite(sprite);
        render.renderUi();
        var i: usize = 0;
        while (i < optionsNum) : (i += 1) {
            _ = render.renderCenteredText(options[i], c.SCREEN_WIDTH / 2, startY + @intCast(c_int, i) * lineGap, 1);
        }
        // Update Screen
        _ = c.SDL_RenderPresent(renderer);
        renderFrames += 1;
    }
    audio.playAudio(c.AUDIO_BUTTON1);
    game.destroySnake(player);
    types.destroyAnimationsByLinkList(&animationsList[c.RENDER_LIST_SPRITE_ID]);
    return cursorPos;
}

pub fn rankListUi(count: c_int, scores: [*c][*c]c.Score) !void {
    baseUi(30, 12 + @maximum(0, count - 4));
    audio.playBgm(0);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    const opts = try allocator.alloc([*c]c.Text, @intCast(c_ulong, count));
    var buf: [1 << 8]u8 = undefined;
    var i: usize = 0;
    while (i < count) : (i += 1) {
        _ = c.sprintf(&buf, "Score: %-6.0lf Got: %-6d Kill: %-6d Damage: %-6d Stand: %-6d", scores[i].*.rank, scores[i].*.got, scores[i].*.killed, scores[i].*.damage, scores[i].*.stand);
        opts[i] = c.createText(&buf, WHITE);
    }

    _ = chooseOptions(count, &opts[0]);

    i = 0;
    while (i < count) : (i += 1) {
        types.destroyText(opts[i]);
    }

    render.blackout();
    render.clearRenderer();
}

pub fn localRankListUi() !void {
    var count: c_int = 0;
    const scores = c.readRanklist(c.STORAGE_PATH, &count);
    try rankListUi(count, scores);
    storage.destroyRanklist(count, scores);
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
    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_UI_ID], &textures[c.RES_TITLE], null, c.LOOP_INFI, 80, c.SCREEN_WIDTH / 2, 280, c.SDL_FLIP_NONE, 0, c.AT_CENTER);
    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_KNIGHT_M], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX, startY, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    var a = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_EFFECT_ID], &textures[c.RES_SwordFx], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX + c.UI_MAIN_GAP_ALT * 2, startY - 32, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    a.*.scaled = false;
    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_CHORT], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX + c.UI_MAIN_GAP_ALT * 2, startY - 32, c.SDL_FLIP_HORIZONTAL, 0, c.AT_BOTTOM_CENTER);

    startX += c.UI_MAIN_GAP_ALT * (6 + 2 * @floatToInt(c_int, c.randDouble()));
    startY += c.UI_MAIN_GAP * (1 + @floatToInt(c_int, c.randDouble()));
    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_ELF_M], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX, startY, c.SDL_FLIP_HORIZONTAL, 0, c.AT_BOTTOM_CENTER);
    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_EFFECT_ID], &textures[c.RES_HALO_EXPLOSION2], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, @floatToInt(c_int, @intToFloat(f64, startX) - @intToFloat(f64, c.UI_MAIN_GAP) * 1.5), startY, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_ZOMBIE], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, @floatToInt(c_int, @intToFloat(f64, startX) - @intToFloat(f64, c.UI_MAIN_GAP) * 1.5), startY, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);

    startX -= @floatToInt(c_int, @intToFloat(f64, c.UI_MAIN_GAP_ALT) * (1.0 + 2.0 * c.randDouble()));
    startY += @floatToInt(c_int, @intToFloat(f64, c.UI_MAIN_GAP) * (2.0 + c.randDouble()));
    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_WIZZARD_M], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX, startY, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_EFFECT_ID], &textures[c.RES_FIREBALL], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX + c.UI_MAIN_GAP, startY, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);

    startX += @floatToInt(c_int, @intToFloat(f64, c.UI_MAIN_GAP_ALT) * (18.0 + 4.0 * c.randDouble()));
    startY -= @floatToInt(c_int, @intToFloat(f64, c.UI_MAIN_GAP) * (1.0 + 3.0 * c.randDouble()));
    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_LIZARD_M], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX, startY, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_EFFECT_ID], &textures[c.RES_CLAWFX2], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX, startY - c.UI_MAIN_GAP + 16, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_MUDDY], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX, startY - c.UI_MAIN_GAP, c.SDL_FLIP_HORIZONTAL, 0, c.AT_BOTTOM_CENTER);

    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_EFFECT_ID], &textures[c.RES_CLAWFX2], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX + c.UI_MAIN_GAP, startY - c.UI_MAIN_GAP + 16, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_SWAMPY], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX + c.UI_MAIN_GAP, startY - c.UI_MAIN_GAP, c.SDL_FLIP_HORIZONTAL, 0, c.AT_BOTTOM_CENTER);

    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_EFFECT_ID], &textures[c.RES_CLAWFX2], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX + c.UI_MAIN_GAP, startY + 16, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);
    _ = render.createAndPushAnimation(&animationsList[c.RENDER_LIST_SPRITE_ID], &textures[c.RES_SWAMPY], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, startX + c.UI_MAIN_GAP, startY, c.SDL_FLIP_HORIZONTAL, 0, c.AT_BOTTOM_CENTER);

    // commented out block in original source is here too.

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    const optsNum: c_int = 4;
    const bytes = try allocator.alloc([*c]c.Text, optsNum);
    var i: usize = 0;
    while (i < optsNum) : (i += 1) {
        bytes[i] = &texts[i + 6];
    }

    const opt: c_int = chooseOptions(optsNum, &bytes[0]);
    try stdout.print("you chose {d}", .{opt});

    render.blackout();
    render.clearRenderer();

    var lan: c_int = 0;
    switch (opt) {
        0 => {
            if (!try chooseLevelUi()) {
                //break;
            }
            try launchLocalGame(1);
            //break;
        },
        1 => {
            lan = c.chooseOnLanUi();
            if (lan == 0) {
                if (!try chooseLevelUi()) {
                    //break;
                }
                try launchLocalGame(2);
            } else if (lan == 1) {
                c.launchLanGame();
            }
            //break;
        },
        2 => {
            try localRankListUi();
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
