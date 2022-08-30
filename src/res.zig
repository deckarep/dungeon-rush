const c = @import("c_headers.zig").c;

const assert = @import("std").debug.assert;
const std = @import("std");
const fmt = std.fmt;
const stdout = std.io.getStdOut().writer();

const types = @import("types.zig");
const weap = @import("weapons.zig");

// Extern.
extern var renderer: ?*c.SDL_Renderer;
extern var weapons: [c.WEAPONS_SIZE]c.Weapon;
extern const WHITE: c.SDL_Color;

// Extern for now.
extern const bgmNums: c_int;
extern var bgms: [c.AUDIO_BGM_SIZE]*c.Mix_Music;
extern const bgmsPath: [c.AUDIO_BGM_SIZE][c.PATH_LEN]u8;

extern var originTextures: [c.TILESET_SIZE]?*c.SDL_Texture;
extern var window: ?*c.SDL_Window;
extern const tilesetPath: [c.TILESET_SIZE][c.PATH_LEN]u8;
extern const fontPath: []u8;
extern var font: ?*c.TTF_Font;
extern var effects: [c.EFFECTS_SIZE]c.Effect;
extern var commonSprites: [c.COMMON_SPRITE_SIZE]c.Sprite;
extern var textures: [c.TEXTURES_SIZE]c.Texture;
extern var soundsCount: c_int;
extern var sounds: [c.AUDIO_SOUND_SIZE]*c.Mix_Chunk;
extern var textsCount: c_int;
extern var texts: [c.TEXTSET_SIZE]c.Text;

pub fn init() bool {
    // Initialization flag
    var success: bool = true;

    // Initialize SDL
    if (c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_AUDIO) < 0) {
        stdout.print("SDL could not initialize! c.SDL_Error: {s}\n", .{c.SDL_GetError()}) catch unreachable;
        success = false;
    } else {
        // Create window
        window = c.SDL_CreateWindow("Dungeon Rush " ++ c.VERSION_STRING, c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, c.SCREEN_WIDTH, c.SCREEN_HEIGHT, c.SDL_WINDOW_SHOWN);
        if (window == null) {
            stdout.print("Window could not be created! c.SDL_Error: {s}\n", .{c.SDL_GetError()}) catch unreachable;
            success = false;
        } else {
            // TODO: use conditional compilation to select render mode in Zig.
            // Software Render
            //#ifndef SOFTWARE_ACC
            renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_ACCELERATED | c.SDL_RENDERER_PRESENTVSYNC);
            //#endif
            //#ifdef SOFTWARE_ACC
            //     stdout.print("define software acc\n") catch unreachable;
            //     renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_SOFTWARE);
            //#endif
            if (renderer == null) {
                stdout.print("Renderer could not be created! SDL Error: {s}\n", .{c.SDL_GetError()}) catch unreachable;
                success = false;
            } else {
                _ = c.SDL_SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF);
                // Initialize PNG loading
                const imgFlags: c_int = c.IMG_INIT_PNG;
                if ((c.IMG_Init(imgFlags) & imgFlags) == 0) {
                    stdout.print("c.SDL_image could not initialize! c.SDL_image Error: {s}\n", .{c.IMG_GetError()}) catch unreachable;
                    success = false;
                }
                if (c.TTF_Init() == -1) {
                    stdout.print("c.SDL_ttf could not initialize! c.SDL_ttf Error: {s}\n", .{c.TTF_GetError()}) catch unreachable;
                    success = false;
                }
                if (c.Mix_OpenAudio(44100, c.MIX_DEFAULT_FORMAT, 2, 2048) < 0) {
                    stdout.print("c.SDL_mixer could not initialize! c.SDL_mixer Error: {s}\n", .{c.Mix_GetError()}) catch unreachable;
                    success = false;
                }
                if (c.SDLNet_Init() == -1) {
                    stdout.print("c.SDL_Net_Init: {s}\n", .{c.SDLNet_GetError()}) catch unreachable;
                    success = false;
                }
            }
        }
    }
    return success;
}

pub fn loadSDLTexture(path: [*c]const u8) ?*c.SDL_Texture {
    // The final texture
    var newTexture: ?*c.SDL_Texture = null;

    // Load image at specified path
    var loadedSurface: ?*c.SDL_Surface = c.IMG_Load(path);
    if (loadedSurface == null) {
        stdout.print("Unable to load image {s}! SDL_image Error: {s}\n", .{ path, c.IMG_GetError() }) catch unreachable;
    } else {
        // Create texture from surface pixels
        newTexture = c.SDL_CreateTextureFromSurface(renderer, loadedSurface);
        if (newTexture == null) {
            stdout.print("Unable to create texture from {s}! SDL Error: {s}\n", .{ path, c.SDL_GetError() }) catch unreachable;
        }

        // Get rid of old loaded surface
        c.SDL_FreeSurface(loadedSurface);
    }

    return newTexture;
}

pub fn loadMedia() bool {
    var success: bool = true;
    initCommonEffects();

    var imgPath: [c.PATH_LEN + 4]u8 = undefined;
    var i: usize = 0;
    while (i < c.TILESET_SIZE) : (i += 1) {
        // TODO: refactor this nonsense.
        const c_string = @ptrCast([*c]const u8, @alignCast(@import("std").meta.alignment(u8), &tilesetPath[@intCast(c_uint, i)]));
        if (!(c.strlen(c_string) != 0)) break;
        _ = c.sprintf(@ptrCast([*c]u8, @alignCast(@import("std").meta.alignment(u8), &imgPath)), "%s.png", @ptrCast([*c]const u8, @alignCast(@import("std").meta.alignment(u8), &tilesetPath[@intCast(c_uint, i)])));

        originTextures[i] = loadSDLTexture(&imgPath);
        _ = loadTileset(c_string, originTextures[i]);

        //stdout.print("type of originTextures[i] {s}\n", .{@TypeOf(originTextures[i])}) catch unreachable;
        success = originTextures[i] != undefined;
    }

    // Open the font
    font = c.TTF_OpenFont("res/font/m5x7.ttf", c.FONT_SIZE);
    if (font == null) {
        stdout.print("Failed to load lazy font! SDL_ttf Error: {s}\n", .{c.TTF_GetError()}) catch unreachable;
        success = false;
    } else {
        if (!loadTextset()) {
            stdout.print("Failed to load textset!\n", .{}) catch unreachable;
            success = false;
        }
    }

    // Init common sprites
    weap.initWeapons();
    initCommonSprites();

    if (!loadAudio()) {
        stdout.print("Failed to load audio!\n", .{}) catch unreachable;
        success = false;
    }

    return success;
}

pub fn loadAudio() bool {
    var success = true;
    var i: usize = 0;
    while (i < bgmNums) : (i += 1) {
        const somePath = bgmsPath[i];
        if (c.Mix_LoadMUS(&somePath[0])) |loaded| {
            bgms[i] = loaded;
        } else {
            stdout.print("Failed to load music {s}: SDL_mixer Error: {s}\n", .{ bgmsPath[i], c.Mix_GetError() }) catch unreachable;
            success = false;
        }
    }

    // NOTE: fuck this shit of loading a file...i'll do it later in a cleaner fashion.
    // NOTE: for now hardcoding a table.
    const soundEffectsTable = &[_][]const u8{
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
    };

    i = 0;
    while (i < soundEffectsTable.len) : (i += 1) {
        const soundsPathPrefix = "res/audio/";
        // IMPORTANT: pass a proper c-string!!!
        var buf: [200]u8 = undefined;
        const soundEffectPath = fmt.bufPrintZ(buf[0..], "{s}{s}", .{ soundsPathPrefix, soundEffectsTable[i] }) catch unreachable;
        if (c.Mix_LoadWAV(soundEffectPath.ptr)) |loaded| {
            sounds[@intCast(usize, soundsCount)] = loaded;
            soundsCount += 1;
        } else {
            stdout.print("Failed to load sound effect \"{s}\": SDL_mixer Error: {s}\n", .{ soundEffectPath, c.Mix_GetError() }) catch unreachable;
            success = false;
        }
    }

    return success;
}

pub fn loadTextset() bool {
    const textTable = &[_][]const u8{
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
    };

    var success = true;

    var i: usize = 0;
    while (i < textTable.len) : (i += 1) {
        const txt = textTable[i];
        // IMPORTANT: pass a proper c-string!!!
        var buf: [200]u8 = undefined;
        const cText = fmt.bufPrintZ(buf[0..], "{s}", .{txt}) catch unreachable;
        if (!c.initText(&texts[@intCast(usize, textsCount)], cText.ptr, WHITE)) {
            success = false;
        }
        textsCount += 1;
    }
    
    return success;
}

pub fn loadTileset(path: [*c]const u8, origin: ?*c.SDL_Texture) bool {
    // TODO: port this over.
    return c.loadTileset(path, origin);
}

pub fn initCommonEffects() void {
    // Effect #0: Death
    types.initEffect(&effects[0], 30, 4, c.SDL_BLENDMODE_BLEND);
    var death = c.SDL_Color{ .r = 255, .g = 255, .b = 255, .a = 255 };

    effects[0].keys[0] = death;
    death.r = 168;
    death.g = 0;
    death.b = 0;
    effects[0].keys[1] = death;
    death.r = 80;
    effects[0].keys[2] = death;
    death.r = 0;
    death.a = 0;
    effects[0].keys[3] = death;
    //#ifdef DBG
    //  puts("Effect #0: Death loaded");
    //#endif

    // Effect #1: Blink ( white )
    types.initEffect(&effects[1], 30, 3, c.SDL_BLENDMODE_ADD);
    var blink = c.SDL_Color{ .r = 0, .g = 0, .b = 0, .a = 255 };
    effects[1].keys[0] = blink;
    blink.r = 200;
    blink.g = 200;
    blink.b = 200;
    effects[1].keys[1] = blink;
    blink.r = 0;
    blink.g = 0;
    blink.b = 0;
    effects[1].keys[2] = blink;
    //#ifdef DBG
    //  puts("Effect #1: Blink (white) loaded");
    //#endif
    types.initEffect(&effects[2], 30, 2, c.SDL_BLENDMODE_BLEND);
    var vanish = c.SDL_Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
    effects[2].keys[0] = vanish;
    vanish.a = 0;
    effects[2].keys[1] = vanish;
    //#ifdef DBG
    //  puts("Effect #2: Vanish (30fm) loaded");
    //#endif
}

pub fn initCommonSprite(sprite: *c.Sprite, weapon: *c.Weapon, res_id: c_int, hp: c_int) void {
    const ani: *c.Animation = c.createAnimation(&textures[@intCast(usize, res_id)], null, c.LOOP_INFI, c.SPRITE_ANIMATION_DURATION, 0, 0, c.SDL_FLIP_NONE, 0, c.AT_BOTTOM_CENTER);

    var sp: c.Sprite = c.Sprite{
        .x = 0,
        .y = 0,
        .hp = hp,
        .totalHp = hp,
        .weapon = weapon,
        .ani = ani,
        .face = c.RIGHT,
        .direction = c.RIGHT,
        .lastAttack = 0,
        .dropRate = 1,
        // this was not specified in the C version.
        .posBuffer = undefined,
    };

    sprite.* = sp;
}

pub fn initCommonSprites() void {
    initCommonSprite(&commonSprites[c.SPRITE_KNIGHT], &weapons[c.WEAPON_SWORD], c.RES_KNIGHT_M, 150);
    initCommonSprite(&commonSprites[c.SPRITE_ELF], &weapons[c.WEAPON_ARROW], c.RES_ELF_M, 100);
    initCommonSprite(&commonSprites[c.SPRITE_WIZZARD], &weapons[c.WEAPON_FIREBALL], c.RES_WIZZARD_M, 95);
    initCommonSprite(&commonSprites[c.SPRITE_LIZARD], &weapons[c.WEAPON_MONSTER_CLAW], c.RES_LIZARD_M, 120);
    initCommonSprite(&commonSprites[c.SPRITE_TINY_ZOMBIE], &weapons[c.WEAPON_MONSTER_CLAW2], c.RES_TINY_ZOMBIE, 50);
    initCommonSprite(&commonSprites[c.SPRITE_GOBLIN], &weapons[c.WEAPON_MONSTER_CLAW2], c.RES_GOBLIN, 100);
    initCommonSprite(&commonSprites[c.SPRITE_IMP], &weapons[c.WEAPON_MONSTER_CLAW2], c.RES_IMP, 100);
    initCommonSprite(&commonSprites[c.SPRITE_SKELET], &weapons[c.WEAPON_MONSTER_CLAW2], c.RES_SKELET, 100);
    initCommonSprite(&commonSprites[c.SPRITE_MUDDY], &weapons[c.WEAPON_SOLID], c.RES_MUDDY, 150);
    initCommonSprite(&commonSprites[c.SPRITE_SWAMPY], &weapons[c.WEAPON_SOLID_GREEN], c.RES_SWAMPY, 150);
    initCommonSprite(&commonSprites[c.SPRITE_ZOMBIE], &weapons[c.WEAPON_MONSTER_CLAW2], c.RES_ZOMBIE, 120);
    initCommonSprite(&commonSprites[c.SPRITE_ICE_ZOMBIE], &weapons[c.WEAPON_ICEPICK], c.RES_ICE_ZOMBIE, 120);
    initCommonSprite(&commonSprites[c.SPRITE_MASKED_ORC], &weapons[c.WEAPON_THROW_AXE], c.RES_MASKED_ORC, 120);
    initCommonSprite(&commonSprites[c.SPRITE_ORC_WARRIOR], &weapons[c.WEAPON_MONSTER_CLAW2], c.RES_ORC_WARRIOR, 200);
    initCommonSprite(&commonSprites[c.SPRITE_ORC_SHAMAN], &weapons[c.WEAPON_MONSTER_CLAW2], c.RES_ORC_SHAMAN, 120);
    initCommonSprite(&commonSprites[c.SPRITE_NECROMANCER], &weapons[c.WEAPON_PURPLE_BALL], c.RES_NECROMANCER, 120);
    initCommonSprite(&commonSprites[c.SPRITE_WOGOL], &weapons[c.WEAPON_MONSTER_CLAW2], c.RES_WOGOL, 150);
    initCommonSprite(&commonSprites[c.SPRITE_CHROT], &weapons[c.WEAPON_MONSTER_CLAW2], c.RES_CHORT, 150);

    var now: *c.Sprite = &commonSprites[c.SPRITE_BIG_ZOMBIE];
    initCommonSprite(now, &weapons[c.WEAPON_THUNDER], c.RES_BIG_ZOMBIE, 3000);
    now.*.dropRate = 100;
    now = &commonSprites[c.SPRITE_ORGRE];
    initCommonSprite(now, &weapons[c.WEAPON_MANY_AXES], c.RES_ORGRE, 3000);
    now.*.dropRate = 100;
    now = &commonSprites[c.SPRITE_BIG_DEMON];
    initCommonSprite(now, &weapons[c.WEAPON_THUNDER], c.RES_BIG_DEMON, 2500);
    now.*.dropRate = 100;
}

pub fn cleanup() void {
    // Deallocate surface
    var i: c_int = 0;
    while (i < c.TILESET_SIZE) : (i += 1) {
        _ = c.SDL_DestroyTexture(originTextures[@intCast(usize, i)]);
        originTextures[@intCast(usize, i)] = undefined;
    }

    // Destroy window
    _ = c.SDL_DestroyRenderer(renderer);
    renderer = undefined;
    _ = c.SDL_DestroyWindow(window);
    window = undefined;

    // Quit SDL subsystems
    _ = c.TTF_Quit();
    _ = c.IMG_Quit();
    _ = c.Mix_CloseAudio();
    _ = c.SDLNet_Quit();
    _ = c.SDL_Quit();
}
