pub const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("time.h");
    @cInclude("unistd.h"); //sleep

    @cInclude("SDL.h");
    @cInclude("SDL_mixer.h");
    @cInclude("SDL_image.h");
    @cInclude("SDL_net.h");
    @cInclude("SDL_ttf.h");
});
