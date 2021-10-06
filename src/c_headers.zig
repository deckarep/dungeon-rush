// Per zig docs and to avoid a struct collision, we should utilize one @cImport per application.
// Previously I had it separate, and this caused different types to be declared that would collide.

// Perhaps splitting out SDL to its own would be ideal.. :/
pub const c = @cImport({
    @cInclude("stdlib.h");

    @cInclude("SDL.h");
    @cInclude("SDL_mixer.h");
    @cInclude("SDL_image.h");
    @cInclude("SDL_net.h");
    @cInclude("SDL_ttf.h");

    @cInclude("res.h");
    @cInclude("ui.h");
    @cInclude("audio.h");
    @cInclude("game.h");
    @cInclude("render.h");
    @cInclude("adt.h");
    @cInclude("types.h");
    @cInclude("helper.h");
    @cInclude("map.h");
    @cInclude("sprite.h");
    @cInclude("weapon.h");
});