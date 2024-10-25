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
const rnd = @import("render.zig");
const tps = @import("types.zig");
const wp = @import("weapons.zig");
const spr = @import("sprite.zig");
const ren = @import("render.zig");
const gAllocator = @import("alloc.zig").gAllocator;

// Resource ID

// Map Resource - this ids correspond to the index at time of load.
pub const RES_WALL_TOP_LEFT = 0;
pub const RES_WALL_TOP_MID = 1;
pub const RES_WALL_TOP_RIGHT = 2;
pub const RES_WALL_MID = 4;
pub const RES_WALL_HOLE_1 = 11;
pub const RES_WALL_HOLE_2 = 12;
pub const RES_WALL_SIDE_TOP_LEFT = 35;
pub const RES_WALL_SIDE_TOP_RIGHT = 36;
pub const RES_WALL_SIDE_MID_LEFT = 37;
pub const RES_WALL_SIDE_MID_RIGHT = 38;
pub const RES_WALL_SIDE_FRONT_LEFT = 39;
pub const RES_WALL_SIDE_FRONT_RIGHT = 40;
pub const RES_WALL_CORNER_TOP_LEFT = 41;
pub const RES_WALL_CORNER_TOP_RIGHT = 42;
pub const RES_WALL_CORNER_LEFT = 43;
pub const RES_WALL_CORNER_RIGHT = 44;
pub const RES_WALL_CORNER_BOTTOM_LEFT = 45;
pub const RES_WALL_CORNER_BOTTOM_RIGHT = 46;
pub const RES_WALL_CORNER_FRONT_LEFT = 47;
pub const RES_WALL_CORNER_FRONT_RIGHT = 48;
pub const RES_WALL_INNER_CORNER_MID_LEFT = 51;
pub const RES_WALL_INNER_CORNER_MID_RIGHT = 52;
pub const RES_WALL_INNER_CORNER_T_TOP_LEFT = 53;
pub const RES_WALL_INNER_CORNER_T_TOP_RIGHT = 54;
pub const RES_WALL_BANNER_RED = 13;
pub const RES_FLOOR_1 = 25;
pub const RES_FLOOR_2 = 26;
pub const RES_FLOOR_3 = 27;
pub const RES_FLOOR_4 = 28;
pub const RES_FLOOR_5 = 29;
pub const RES_FLOOR_6 = 30;
pub const RES_FLOOR_7 = 31;
pub const RES_FLOOR_8 = 32;
pub const RES_FLASK_RED = 70;
pub const RES_FLASK_BIG_RED = 66;
pub const RES_FLASK_BIG_BLUE = 67;
pub const RES_FLASK_BIG_GREEN = 68;
pub const RES_FLASK_BIG_YELLOW = 69;
pub const RES_SKULL = 74;
pub const RES_TINY_ZOMBIE = 102;
pub const RES_GOBLIN = 104;
pub const RES_IMP = 106;
pub const RES_SKELET = 108;
pub const RES_MUDDY = 110;
pub const RES_SWAMPY = 112;
pub const RES_ZOMBIE = 114;
pub const RES_ICE_ZOMBIE = 116;
pub const RES_MASKED_ORC = 118;
pub const RES_ORC_WARRIOR = 120;
pub const RES_ORC_SHAMAN = 122;
pub const RES_NECROMANCER = 124;
pub const RES_WOGOL = 126;
pub const RES_CHORT = 128;
pub const RES_BIG_ZOMBIE = 130;
pub const RES_ORGRE = 132;
pub const RES_BIG_DEMON = 134;
pub const RES_ELF_F = 136;
pub const RES_ELF_M = 139;
pub const RES_KNIGHT_M = 142; //145 (male night)
pub const RES_WIZZARD_M = 151;
pub const RES_LIZARD_M = 157;
pub const RES_ZIGGY_M = 160;
pub const RES_FLOOR_SPIKE_DISABLED = 166;
pub const RES_FLOOR_SPIKE_ENABLED = 167;
pub const RES_FLOOR_SPIKE_OUT_ANI = 168;
pub const RES_FLOOR_SPIKE_IN_ANI = 169;
pub const RES_FLOOR_EXIT = 170;
pub const RES_HALO_EXPLOSION1 = 163;
pub const RES_HALO_EXPLOSION2 = 164;
pub const RES_FIREBALL = 165;
pub const RES_HP_MED = 171;
pub const RES_SwordFx = 172;
pub const RES_CLAWFX = 173;
pub const RES_Shine = 174;
pub const RES_Thunder = 175;
pub const RES_BLOOD_BOUND = 176;
pub const RES_ARROW = 177;
pub const RES_EXPOLSTION2 = 178;
pub const RES_CLAWFX2 = 179;
pub const RES_AXE = 180;
pub const RES_CROSS_HIT = 181;
pub const RES_BLOOD1 = 182;
pub const RES_BLOOD4 = 185;
pub const RES_SOLIDFX = 186;
pub const RES_SOLID_GREENFX = 187;
pub const RES_ICEPICK = 188;
pub const RES_ICESHATTER = 189;
pub const RES_ICE = 190;
pub const RES_HOLY_SWORD = 191;
pub const RES_FIRE_SWORD = 192;
pub const RES_ICE_SWORD = 193;
pub const RES_GRASS_SWORD = 194;
pub const RES_IRON_SWORD = 195;
pub const RES_HOLY_SHIELD = 196;
pub const RES_GOLDEN_CROSS_HIT = 197;
pub const RES_SLIDER = 198;
pub const RES_BAR_BLUE = 199;
pub const RES_TITLE = 200;
pub const RES_PURPLE_BALL = 201;
pub const RES_PURPLE_EXP = 202;
pub const RES_PURPLE_STAFF = 203;
pub const RES_THUNDER_STAFF = 204;
pub const RES_THUNDER_YELLOW = 205;
pub const RES_ATTACK_UP = 206;
pub const RES_POWERFUL_BOW = 207;

// Effect
pub const EFFECT_DEATH = 0;
pub const EFFECT_BLINK = 1;
pub const EFFECT_VANISH30 = 2;

// Sprite
pub const COMMON_SPRITE_SIZE = 1024;
pub const SPRITE_KNIGHT = 0;
pub const SPRITE_ELF = 1;
pub const SPRITE_WIZZARD = 2;
pub const SPRITE_LIZARD = 3;
pub const SPRITE_TINY_ZOMBIE = 4;
pub const SPRITE_GOBLIN = 5;
pub const SPRITE_IMP = 6;
pub const SPRITE_SKELET = 7;
pub const SPRITE_MUDDY = 8;
pub const SPRITE_SWAMPY = 9;
pub const SPRITE_ZOMBIE = 10;
pub const SPRITE_ICE_ZOMBIE = 11;
pub const SPRITE_MASKED_ORC = 12;
pub const SPRITE_ORC_WARRIOR = 13;
pub const SPRITE_ORC_SHAMAN = 14;
pub const SPRITE_NECROMANCER = 15;
pub const SPRITE_WOGOL = 16;
pub const SPRITE_CHROT = 17;
pub const SPRITE_BIG_ZOMBIE = 18;
pub const SPRITE_ORGRE = 19;
pub const SPRITE_BIG_DEMON = 20;

// Audio
pub const AUDIO_BGM_SIZE = 16;
pub const AUDIO_SOUND_SIZE = 256;
pub const AUDIO_WIN = 0;
pub const AUDIO_LOSE = 1;
pub const AUDIO_POWERLOSS = 2;
pub const AUDIO_HIT = 3;
pub const AUDIO_SWORD_HIT = 4;
pub const AUDIO_CLAW_HIT = 5;
pub const AUDIO_ARROW_HIT = 6;
pub const AUDIO_SHOOT = 7;
pub const AUDIO_FIREBALL_EXP = 8;
pub const AUDIO_ICE_SHOOT = 9;
pub const AUDIO_INTER1 = 10;
pub const AUDIO_BUTTON1 = 11;
pub const AUDIO_THUNDER = 12;
pub const AUDIO_LIGHT_SHOOT = 13;
pub const AUDIO_HUMAN_DEATH = 14;
pub const AUDIO_CLAW_HIT_HEAVY = 15;
pub const AUDIO_COIN = 16;
pub const AUDIO_MED = 17;
pub const AUDIO_HOLY = 18;
// End Resource ID

pub const UNIT = 32;
pub const SCREEN_WIDTH = 1440;
pub const SCREEN_HEIGHT = 960;
pub const n = SCREEN_WIDTH / UNIT;
pub const m = SCREEN_HEIGHT / UNIT;

pub const FONT_SIZE = 32;
pub const PATH_LEN = 1024;
pub const TILESET_SIZE = 1024;
pub const TEXTSET_SIZE = 1024;
pub const EFFECTS_SIZE = 128;
pub const bgmNums = 4;
pub const TEXTURES_SIZE = 1024;

pub const nameOfTheGame = "Dungeon Rush: Zig-Edition v1.0 - by @deckarep";

const fontPath = "res/font/m5x7.ttf";
const soundsPath = "res/audio/";
const soundsPathPrefix = "res/audio/";

// NOTE: the text file and .png tilesets must match in name.
const tilesetPath = &[_][]const u8{
    "res/drawable/0x72_DungeonTilesetII_v1_3",
    "res/drawable/fireball_explosion1",
    "res/drawable/halo_explosion1",
    "res/drawable/halo_explosion2",
    "res/drawable/fireball",
    "res/drawable/floor_spike",
    "res/drawable/floor_exit",
    "res/drawable/HpMed",
    "res/drawable/SwordFx",
    "res/drawable/ClawFx",
    "res/drawable/Shine",
    "res/drawable/Thunder",
    "res/drawable/BloodBound",
    "res/drawable/arrow",
    "res/drawable/explosion-2",
    "res/drawable/ClawFx2",
    "res/drawable/Axe",
    "res/drawable/cross_hit",
    "res/drawable/blood",
    "res/drawable/SolidFx",
    "res/drawable/IcePick",
    "res/drawable/IceShatter",
    "res/drawable/Ice",
    "res/drawable/SwordPack",
    "res/drawable/HolyShield",
    "res/drawable/golden_cross_hit",
    "res/drawable/ui",
    "res/drawable/title",
    "res/drawable/purple_ball",
    "res/drawable/purple_exp",
    "res/drawable/staff",
    "res/drawable/Thunder_Yellow",
    "res/drawable/attack_up",
    "res/drawable/powerful_bow",
};

pub const textList = &[_][*:0]const u8{
    // r.c.: Moved to a static embedded list cause I don't want to do file-io right now.
    "DungeonRush",
    "By Rapiz",
    "PLACEHOLDER",
    "PLACEHOLDER",
    "Player 1",
    "Player 2",
    "Singleplayer",
    "Multiplayers",
    "Ranklist",
    "Exit",
    "Normal",
    "Hard",
    "Insane",
    "Local",
    "Lan",
    "Host a game",
    "Join a game",
    "Zig Edition: by @deckarep - (c) 2024", // <-- that's me!
};

const bgmsPath = &[_][]const u8{
    "res/audio/main_title.ogg",
    "res/audio/bg1.ogg",
    "res/audio/bg2.ogg",
    "res/audio/bg3.ogg",
};
const soundfxList = &[_][]const u8{
    // r.c.: Moved to a static embedded list cause I don't want to do file-io right now.
    "win.wav",
    "lose_2v.wav",
    "powerloss.wav",
    "hit_0.5v.wav",
    "sword_hit.wav",
    "claw_hit.wav",
    "arrow_hit.wav",
    "shoot.wav",
    "fireball_explosion.wav",
    "ice_shoot_0.5v.wav",
    "interaction1_0.75v.wav",
    "button1.wav",
    "thunder_2v.wav",
    "light_shoot.wav",
    "human_death.wav",
    "claw_hit_heavy.wav",
    "coin.wav",
    "med.wav",
    "holy.ogg",
};

// Globals
pub var textures: [TEXTURES_SIZE]tps.Texture = undefined;
pub var texturesCount: usize = 0;
pub var bgms: [AUDIO_BGM_SIZE]?*c.Mix_Music = undefined;
pub var commonSprites: [COMMON_SPRITE_SIZE]spr.Sprite = undefined;
var commonSpriteCounter: usize = 0;
pub var font: *c.TTF_Font = undefined;
pub var sounds: [AUDIO_SOUND_SIZE]?*c.Mix_Chunk = undefined;
pub var texts: [TEXTSET_SIZE]tps.Text = undefined;
var window: *c.SDL_Window = undefined;
var originTextures: [TILESET_SIZE]?*c.SDL_Texture = undefined;
pub var effects: [EFFECTS_SIZE]tps.Effect = undefined;
var soundsCount: usize = 0;

pub fn init() bool {
    var success = true;
    if (c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_AUDIO) < 0) {
        _ = c.printf("SDL could not initialize! SDL_Error: %s\n", c.SDL_GetError());
        success = false;
    } else {
        // NOTE: enabled high-dpi mode and window resizing.
        // Taken from: https://github.com/midzer/DungeonRush/commit/a78751d4cd3bd336e4499b17f2772a57c0cb5b2a
        const win = c.SDL_CreateWindow(
            nameOfTheGame,
            c.SDL_WINDOWPOS_CENTERED,
            c.SDL_WINDOWPOS_CENTERED,
            SCREEN_WIDTH / 2, // Half for high dpi mode.
            SCREEN_HEIGHT / 2, // Same.
            c.SDL_WINDOW_ALLOW_HIGHDPI | c.SDL_WINDOW_RESIZABLE,
        );
        if (win) |w| {
            window = w;

            const rend = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_ACCELERATED); //| c.SDL_RENDERER_PRESENTVSYNC);
            if (rend == null) {
                _ = c.printf("Renderer could not be created! SDL Error: %s\n", c.SDL_GetError());
                success = false;
            } else {
                rnd.renderer = rend.?;
                _ = c.SDL_SetRenderDrawColor(rnd.renderer, 0xff, 0xff, 0xff, 0xff);
                // Added for high dpi mode!
                _ = c.SDL_RenderSetLogicalSize(ren.renderer, SCREEN_WIDTH, SCREEN_HEIGHT);

                const imgFlags: c_int = c.IMG_INIT_PNG;
                if (!((c.IMG_Init(imgFlags) & imgFlags) != 0)) {
                    _ = c.printf("SDL_image could not initialize! SDL_image Error: %s\n", c.SDL_GetError());
                    success = false;
                }
                if (c.TTF_Init() == -1) {
                    _ = c.printf("SDL_ttf could not initialize! SDL_ttf Error: %s\n", c.SDL_GetError());
                    success = false;
                }
                if (c.Mix_OpenAudio(44100, c.MIX_DEFAULT_FORMAT, 2, 2048) < 0) {
                    _ = c.printf("SDL_mixer could not initialize! SDL_mixer Error: %s\n", c.SDL_GetError());
                    success = false;
                }
                if (c.SDLNet_Init() == -1) {
                    _ = c.printf("SDL_Net_Init: %s\n", c.SDLNet_GetError());
                    success = false;
                }
            }
        }
    }

    return success;
}

pub fn loadSDLTexture(path: [:0]const u8) ?*c.SDL_Texture {
    // Load teexture at specified path.
    const texture = c.IMG_LoadTexture(ren.renderer, path);
    if (texture == null) {
        std.log.err("Unable to create texture from: {s}. SDL Error: {s}", .{ path, c.SDL_GetError() });
    }
    return texture;
}

fn loadTextset() bool {
    var success = true;
    var count: usize = 0;
    for (0..textList.len) |idx| {
        const str = textList[idx];
        if (!tps.initText(&texts[idx], str, tps.WHITE)) {
            success = false;
            break;
        }
        count += 1;
    }

    // Total hack, create a dynamic textset as a FPS counter.
    // This is here to just use what's in place and still be performant.
    // You wouldn't get it script kiddy.
    // NOTE: as of now, these lives for the life of the app and is never cleaned up.
    for (0..61) |i| {
        // NOTE: initTexts copies the text, so we just free it asap.
        const res = std.fmt.allocPrintZ(gAllocator, "FPS: {d}", .{i}) catch unreachable;
        defer gAllocator.free(res);

        if (!tps.initText(&texts[count + i], res.ptr, tps.WHITE)) {
            success = false;
            break;
        }
    }

    return success;
}

fn loadTileset(path: [*]const u8, origin: ?*c.SDL_Texture) bool {
    if (origin == null) {
        @panic("origin should never be null!");
    }

    const file = c.fopen(path, "r");
    defer _ = c.fclose(file);

    var x: c_int = undefined;
    var y: c_int = undefined;
    var w: c_int = undefined;
    var h: c_int = undefined;
    var f: c_int = undefined;

    var resName: [256]u8 = undefined;

    // Convention of tileset: name, x, y, w, h, f (num of frames)
    while (c.fscanf(file, "%s %d %d %d %d %d", &resName, &x, &y, &w, &h, &f) == 6) {
        const p = &textures[texturesCount];
        texturesCount += 1;
        tps.initTexture(p, origin.?, w, h, f);

        var i: usize = 0;
        while (i < f) : (i += 1) {
            p.crops[i].x = x + @as(c_int, @intCast(i)) * w;
            p.crops[i].y = y;
            p.crops[i].h = h;
            p.crops[i].w = w;
        }

        p.dbgName = resName;

        std.log.debug("Texture Res: {d}). {s} ptr:{*}, x:{d}, y:{d}, w:{d}, h:{d}, f:{d}", .{
            texturesCount - 1,
            std.mem.sliceTo(&p.dbgName, 0),
            p,
            x,
            y,
            w,
            h,
            f,
        });
    }
    return true;
}

pub fn loadAudio() !bool {
    for (0..bgmNums) |i| {
        const mus = c.Mix_LoadMUS(bgmsPath[i].ptr);
        if (mus) |mu| {
            bgms[i] = mu;
        } else {
            _ = c.printf(
                "Failed to load %s: SDL_mixer Error: %s\n",
                bgmsPath[i].ptr,
                c.Mix_GetError(),
            );
            return false;
        }
    }

    for (0..soundfxList.len) |i| {
        var buf: [PATH_LEN]u8 = undefined;
        const path = try std.fmt.bufPrintZ(&buf, "{s}{s}", .{ soundsPath, soundfxList[i] });
        const sfx = c.Mix_LoadWAV(path.ptr);
        if (sfx) |snd| {
            sounds[soundsCount] = snd;
            soundsCount += 1;
        } else {
            _ = c.printf(
                "Failed to load %s: : SDL_mixer Error: %s\n",
                path.ptr,
                c.Mix_GetError(),
            );
            return false;
        }
    }

    return true;
}

pub fn loadMedia() !bool {
    // load effects
    initCommonEffects();

    // Load tileset
    for (tilesetPath, 0..) |path, idx| {
        var buf: [PATH_LEN + 4]u8 = undefined;
        const img = try std.fmt.bufPrintZ(&buf, "{s}.png", .{path});

        originTextures[idx] = loadSDLTexture(std.mem.sliceTo(img, 0));
        const pptr = path.ptr;
        _ = loadTileset(pptr, originTextures[idx]);
        if (originTextures[idx] == null) {
            return false;
        }
    }

    // Open the font
    const fnt = c.TTF_OpenFont(fontPath, FONT_SIZE);
    if (fnt) |f| {
        font = f;
    } else {
        _ = c.printf("Failed to load lazy font! SDL_ttf Error: %s\n", c.TTF_GetError());
        return false;
    }

    if (!loadTextset()) {
        _ = c.printf("Failed to load textset!\n");
        return false;
    }

    // Init common sprites
    wp.initWeapons();
    initCommonSprites();

    if (!try loadAudio()) {
        _ = c.printf("Failed to load audio!\n");
        return false;
    }

    return true;
}

pub fn cleanup() void {
    for (0..TILESET_SIZE) |idx| {
        c.SDL_DestroyTexture(originTextures[idx]);
        originTextures[idx] = null;
    }

    // NOTE: r.c. added by me - destroy all animations!
    for (0..ren.ANIMATION_LINK_LIST_NUM) |i| {
        tps.destroyAnimationsByLinkList(&ren.animationsList[i]);
    }

    // These live for the life of the app, but I'm destroy them so we have no leaks at the end.
    for (0..commonSpriteCounter) |i| {
        gAllocator.destroy(commonSprites[i].ani);
    }
    // These also live for the life of the app.
    wp.destroyWeapons();

    // Effects also live for the life of the app and should be cleaned up.
    // NOTE: 3 is hardoded - baaaad.
    for (0..3) |i| {
        gAllocator.free(effects[i].keys);
    }

    // Clean up long-lived texture crops, which are dynamically alloc'd.
    for (0..texturesCount) |i| {
        gAllocator.free(textures[i].crops);
    }

    ren.clearInfo();

    c.SDL_DestroyRenderer(rnd.renderer);
    // rnd.renderer = null; // rc: choosing to use non-nullable var.
    c.SDL_DestroyWindow(window);
    // window = null; // rc: choosing to use non-nullable var.
    c.TTF_Quit();
    c.IMG_Quit();
    c.Mix_CloseAudio();
    c.SDLNet_Quit();
    c.SDL_Quit();
}

pub fn initCommonEffects() void {
    tps.initEffect(&effects[0], 30, 4, c.SDL_BLENDMODE_BLEND);
    var death: c.SDL_Color = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
    effects[0].keys[0] = death;
    death.g = 0;
    death.b = 0;
    death.r = 168;
    effects[0].keys[1] = death;
    death.r = 80;
    effects[0].keys[2] = death;
    death.r = 0;
    death.a = 0;
    effects[0].keys[0] = death;

    tps.initEffect(&effects[1], 30, 3, c.SDL_BLENDMODE_ADD);
    var blink: c.SDL_Color = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
    effects[1].keys[0] = blink;
    blink.r = 200;
    blink.g = 200;
    blink.b = 200;
    effects[1].keys[1] = blink;
    blink.r = 0;
    blink.g = 0;
    blink.b = 0;
    effects[1].keys[2] = blink;

    tps.initEffect(&effects[2], 30, 2, c.SDL_BLENDMODE_BLEND);
    var vanish: c.SDL_Color = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
    effects[2].keys[0] = vanish;
    vanish.a = 0;
    effects[2].keys[1] = vanish;
}

fn initCommonSprite(sprite: *spr.Sprite, weapon: *wp.Weapon, res_id: c_int, hp: c_int) void {
    const rid: usize = @intCast(res_id);
    const ani = tps.createAnimation(
        &textures[rid],
        null,
        .LOOP_INFI,
        ren.SPRITE_ANIMATION_DURATION,
        0,
        0,
        c.SDL_FLIP_NONE,
        0,
        .AT_BOTTOM_CENTER,
    );
    sprite.* = .{
        .x = 0,
        .y = 0,
        .hp = hp,
        .totalHp = hp,
        .weapon = weapon,
        .ani = ani,
        .face = .RIGHT,
        .direction = .RIGHT,
        .lastAttack = 0,
        .dropRate = 1,
    };

    commonSpriteCounter += 1;
}

fn initCommonSprites() void {
    // Heroes
    initCommonSprite(&commonSprites[SPRITE_KNIGHT], &wp.weapons[wp.WEAPON_SWORD], RES_KNIGHT_M, 150);
    initCommonSprite(&commonSprites[SPRITE_ELF], &wp.weapons[wp.WEAPON_ARROW], RES_ELF_M, 100);
    initCommonSprite(&commonSprites[SPRITE_WIZZARD], &wp.weapons[wp.WEAPON_FIREBALL], RES_WIZZARD_M, 95);
    initCommonSprite(&commonSprites[SPRITE_LIZARD], &wp.weapons[wp.WEAPON_MONSTER_CLAW], RES_ZIGGY_M, 120);

    // Baddies
    initCommonSprite(&commonSprites[SPRITE_TINY_ZOMBIE], &wp.weapons[wp.WEAPON_MONSTER_CLAW2], RES_TINY_ZOMBIE, 50);
    initCommonSprite(&commonSprites[SPRITE_GOBLIN], &wp.weapons[wp.WEAPON_MONSTER_CLAW2], RES_GOBLIN, 100);
    initCommonSprite(&commonSprites[SPRITE_IMP], &wp.weapons[wp.WEAPON_MONSTER_CLAW2], RES_IMP, 100);
    initCommonSprite(&commonSprites[SPRITE_SKELET], &wp.weapons[wp.WEAPON_MONSTER_CLAW2], RES_SKELET, 100);
    initCommonSprite(&commonSprites[SPRITE_MUDDY], &wp.weapons[wp.WEAPON_SOLID], RES_MUDDY, 150);
    initCommonSprite(&commonSprites[SPRITE_SWAMPY], &wp.weapons[wp.WEAPON_SOLID_GREEN], RES_SWAMPY, 150);
    initCommonSprite(&commonSprites[SPRITE_ZOMBIE], &wp.weapons[wp.WEAPON_MONSTER_CLAW2], RES_ZOMBIE, 120);
    initCommonSprite(&commonSprites[SPRITE_ICE_ZOMBIE], &wp.weapons[wp.WEAPON_ICEPICK], RES_ICE_ZOMBIE, 120);
    initCommonSprite(&commonSprites[SPRITE_MASKED_ORC], &wp.weapons[wp.WEAPON_THROW_AXE], RES_MASKED_ORC, 120);
    initCommonSprite(&commonSprites[SPRITE_ORC_WARRIOR], &wp.weapons[wp.WEAPON_MONSTER_CLAW2], RES_ORC_WARRIOR, 200);
    initCommonSprite(&commonSprites[SPRITE_ORC_SHAMAN], &wp.weapons[wp.WEAPON_MONSTER_CLAW2], RES_ORC_SHAMAN, 120);
    initCommonSprite(&commonSprites[SPRITE_NECROMANCER], &wp.weapons[wp.WEAPON_PURPLE_BALL], RES_NECROMANCER, 120);
    initCommonSprite(&commonSprites[SPRITE_WOGOL], &wp.weapons[wp.WEAPON_MONSTER_CLAW2], RES_WOGOL, 150);
    initCommonSprite(&commonSprites[SPRITE_CHROT], &wp.weapons[wp.WEAPON_MONSTER_CLAW2], RES_CHORT, 150);

    var now: *spr.Sprite = undefined;

    now = &commonSprites[SPRITE_BIG_ZOMBIE];
    now.dropRate = 100;
    initCommonSprite(now, &wp.weapons[wp.WEAPON_THUNDER], RES_BIG_ZOMBIE, 3000);

    now = &commonSprites[SPRITE_ORGRE];
    now.dropRate = 100;
    initCommonSprite(now, &wp.weapons[wp.WEAPON_MANY_AXES], RES_ORGRE, 3000);

    now = &commonSprites[SPRITE_BIG_DEMON];
    now.dropRate = 100;
    initCommonSprite(now, &wp.weapons[wp.WEAPON_THUNDER], RES_BIG_DEMON, 2500);
}
