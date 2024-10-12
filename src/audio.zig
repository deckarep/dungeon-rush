const c = @import("cdefs.zig").c;
const res = @import("res.zig");

const BGM_FADE_DURATION = 800;

var nowBgmId: c_int = -1;

pub fn playBgm(id: c_int) void {
    if (nowBgmId == id) {
        return;
    }
    if (nowBgmId == -1) {
        _ = c.Mix_PlayMusic(res.bgms[@intCast(id)], -1);
    } else {
        _ = c.Mix_FadeInMusic(res.bgms[@intCast(id)], -1, BGM_FADE_DURATION);
    }

    nowBgmId = id;
}

pub fn stopBgm() void {
    _ = c.Mix_FadeOutMusic(BGM_FADE_DURATION);
    nowBgmId = -1;
}

pub fn playAudio(id: usize) void {
    if (id >= 0) {
        _ = c.Mix_PlayChannel(-1, res.sounds[id], 0);
    }
}
