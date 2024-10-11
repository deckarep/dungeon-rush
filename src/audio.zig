const c = @import("cdefs.zig").c;
const res = @import("res.zig");

const BGM_FADE_DURATION = 800;

var nowBgmId: usize = undefined;

pub fn playBgm(id: usize) void {
    if (nowBgmId == id) {
        _ = c.printf("returning...");
        return;
    }
    if (nowBgmId == undefined) {
        _ = c.printf("a...");
        _ = c.Mix_PlayMusic(res.bgms[id], -1);
    } else {
        _ = c.printf("b...");
        _ = c.Mix_FadeInMusic(res.bgms[id], -1, BGM_FADE_DURATION);
    }

    nowBgmId = id;
}

pub fn stopBgm() void {
    _ = c.Mix_FadeOutMusic(BGM_FADE_DURATION);
    nowBgmId = undefined;
}

pub fn playAudio(id: usize) void {
    if (id >= 0) {
        _ = c.Mix_PlayChannel(-1, res.sounds[id], 0);
    }
}
