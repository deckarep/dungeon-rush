const c = @import("c_headers.zig").c;

const assert = @import("std").debug.assert;
const std = @import("std");
const stdout = std.io.getStdOut().writer();

// Extern.
extern var renderer: ?*c.SDL_Renderer;

// Extern for now.
extern var originTextures: [c.TILESET_SIZE]*c.SDL_Texture;
extern var window: ?*c.SDL_Window;
extern const tilesetPath: [c.TILESET_SIZE][c.PATH_LEN]u8;

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
                // Initialize c.SDL_ttf
                if (c.TTF_Init() == -1) {
                    stdout.print("c.SDL_ttf could not initialize! c.SDL_ttf Error: {s}\n", .{c.TTF_GetError()}) catch unreachable;
                    success = false;
                }
                //Initialize c.SDL_mixer
                if (c.Mix_OpenAudio(44100, c.MIX_DEFAULT_FORMAT, 2, 2048) < 0) {
                    stdout.print("c.SDL_mixer could not initialize! c.SDL_mixer Error: {s}\n", .{c.Mix_GetError()}) catch unreachable;
                    success = false;
                }
                //Initialize c.SDL_net
                if (c.SDLNet_Init() == -1) {
                    stdout.print("c.SDL_Net_Init: {s}\n", .{c.SDLNet_GetError()}) catch unreachable;
                    success = false;
                }
            }
        }
    }
    return success;
}

pub fn loadMedia() bool {
    return c.loadMedia();
    // var success:bool = false;
    // c.initCommonEffects();

    // char imgPath[PATH_LEN + 4];
    // for (int i = 0; i < TILESET_SIZE; i++) {
    //     if (!strlen(tilesetPath[i])) break;
    //     sprintf(imgPath, "%s.png", tilesetPath[i]);
    //     originTextures[i] = loadSDLTexture(imgPath);
    //     loadTileset(tilesetPath[i], originTextures[i]);
    //     success &= (bool)originTextures[i];
    // }

    // Load tileset
    // var imgPath:[c.PATH_LEN + 4]u8 = undefined;
    // var i:usize = 0;
    // while( i < c.TILESET_SIZE) : ( i+=1 ){
    //     if (tilesetPath[i].len == 0) {
    //         break;
    //     }
    // }
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
