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

const c = @import("cdefs.zig").c;
const res = @import("res.zig");
const hlp = @import("helper.zig");

const BGM_FADE_DURATION = 800;

var nowBgmId: ?usize = null;

pub fn playBgm(id: usize) void {
    // NOTE: temporary disabling music, as it's getting old.
    if (true or id == nowBgmId) {
        return;
    }

    if (nowBgmId == null) {
        _ = c.Mix_PlayMusic(res.bgms[@intCast(id)], -1);
    } else {
        _ = c.Mix_FadeInMusic(res.bgms[@intCast(id)], -1, BGM_FADE_DURATION);
    }

    nowBgmId = id;
}

pub fn stopBgm() void {
    _ = c.Mix_FadeOutMusic(BGM_FADE_DURATION);
    nowBgmId = null;
}

/// randomBgm selects a random background music track from 1.. because track
/// 0 is reserved for the game menu.
pub fn randomBgm() void {
    const r: usize = @intCast(hlp.randInt(1, res.bgmsPath.len - 1));
    playBgm(r);
}

pub fn playAudio(id: usize) void {
    if (id >= 0) {
        _ = c.Mix_PlayChannel(-1, res.sounds[id], 0);
    }
}

pub fn pauseSound() void {
    _ = c.Mix_Pause(-1);
    _ = c.Mix_PauseMusic();
}
pub fn resumeSound() void {
    _ = c.Mix_Resume(-1);
    _ = c.Mix_ResumeMusic();
}
