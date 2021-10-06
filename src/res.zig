const c = @import("c_headers.zig").c;

const assert = @import("std").debug.assert;
const std = @import("std");
const stdout = std.io.getStdOut().writer();

// Extern.
extern var renderer: ?*c.SDL_Renderer;

// Extern for now.
extern var originTextures: [c.TILESET_SIZE]?*c.SDL_Texture;
extern var window: ?*c.SDL_Window;
extern const tilesetPath: [c.TILESET_SIZE][c.PATH_LEN]u8;
extern const fontPath: []u8;
extern var font: ?*c.TTF_Font;
extern var effects: [c.EFFECTS_SIZE]c.Effect;

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
    //return c.loadMedia();
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
        _ = c.loadTileset(c_string, originTextures[i]);

        stdout.print("type of originTextures[i] {s}\n", .{@TypeOf(originTextures[i])}) catch unreachable;
        success = originTextures[i] != undefined;
    }

    // Open the font
    font = c.TTF_OpenFont("res/font/m5x7.ttf", c.FONT_SIZE);
    if (font == null) {
        stdout.print("Failed to load lazy font! SDL_ttf Error: {s}\n", .{c.TTF_GetError()}) catch unreachable;
        success = false;
    } else {
        if (!c.loadTextset()) {
            stdout.print("Failed to load textset!\n", .{}) catch unreachable;
            success = false;
        }
    }

    // Init common sprites
    c.initWeapons();
    c.initCommonSprites();

    if (!c.loadAudio()) {
        stdout.print("Failed to load audio!\n", .{}) catch unreachable;
        success = false;
    }

    return success;
}

pub fn initCommonEffects() void {
    // Effect #0: Death
    c.initEffect(&effects[0], 30, 4, c.SDL_BLENDMODE_BLEND);
    var death = c.SDL_Color{.r=255, .g=255, .b=255, .a=255};

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
    c.initEffect(&effects[1], 30, 3, c.SDL_BLENDMODE_ADD);
    var blink = c.SDL_Color{.r=0, .g=0, .b=0, .a=255};
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
    c.initEffect(&effects[2], 30, 2, c.SDL_BLENDMODE_BLEND);
    var vanish = c.SDL_Color{.r=255, .g=255, .b=255, .a=255};
    effects[2].keys[0] = vanish;
    vanish.a = 0;
    effects[2].keys[1] = vanish;
    //#ifdef DBG
    //  puts("Effect #2: Vanish (30fm) loaded");
    //#endif
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
