const std = @import("std");
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;
const rand = @import("std").rand;

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
        _ = c.Mix_PlayMusic(bgms[@intCast(usize, id)], -1);
    } else {
        _ = c.Mix_FadeInMusic(bgms[@intCast(usize, id)], -1, c.BGM_FADE_DURATION);
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
    playBgm(rand.int(1, bgmNums - 1));
}

pub fn playAudio(id: c_int) void {
    stdout.print("playAudio\n", .{}) catch unreachable;
    if (id >= 0) {
        _ = c.Mix_PlayChannel(-1, sounds[id], 0);
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
