const std = @import("std");
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;
// TODO: figure out a random comptime seed.
var prng = std.rand.DefaultPrng.init(3);
const rand = prng.random();

extern const bgmNums: c_int;
extern var bgms: [c.AUDIO_BGM_SIZE]*c.Mix_Music;
extern var sounds: [c.AUDIO_SOUND_SIZE]*c.Mix_Chunk;

var nowBgmId: c_int = -1;

pub fn playBgm(id: c_int) void {
    stdout.print("playBgm\n", .{}) catch unreachable;
    if (nowBgmId == id) {
        return;
    }
    if (nowBgmId == -1) {
        _ = c.Mix_PlayMusic(bgms[@intCast(id)], -1);
    } else {
        _ = c.Mix_FadeInMusic(bgms[@intCast(id)], -1, c.BGM_FADE_DURATION);
    }
    nowBgmId = id;
}

pub fn stopBgm() void {
    stdout.print("stopBgm\n", .{}) catch unreachable;
    _ = c.Mix_FadeOutMusic(c.BGM_FADE_DURATION);
    nowBgmId = -1;
}

pub fn randomBgm() void {
    stdout.print("randomBgm\n", .{}) catch unreachable;
    const r = rand.intRangeAtMost(c_int, 1, bgmNums - 1);
    playBgm(r);
}

pub fn playAudio(id: c_int) void {
    stdout.print("playAudio\n", .{}) catch unreachable;
    if (id >= 0) {
        _ = c.Mix_PlayChannel(-1, sounds[@intCast(id)], 0);
    }
}

pub fn pauseSound() void {
    stdout.print("pauseSound\n", .{}) catch unreachable;
    _ = c.Mix_Pause(-1);
    _ = c.Mix_PauseMusic();
}
pub fn resumeSound() void {
    stdout.print("resumeSound\n", .{}) catch unreachable;
    _ = c.Mix_Resume(-1);
    _ = c.Mix_ResumeMusic();
}
