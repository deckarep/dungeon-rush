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

const std = @import("std");
const tps = @import("types.zig");
const wp = @import("weapons.zig");
const ren = @import("render.zig");
const c = @import("cdefs.zig").c;
const gAllocator = @import("alloc.zig").gAllocator;

pub const PositionBufferSlot = struct {
    x: c_int,
    y: c_int,
    direction: tps.Direction,
};

pub const PositionBuffer = struct {
    buffer: [tps.POSITION_BUFFER_SIZE]PositionBufferSlot,
    size: usize,
};

pub const Sprite = struct {
    x: c_int,
    y: c_int,
    hp: c_int,
    totalHp: c_int,

    weapon: *wp.Weapon,
    ani: *tps.Animation,
    face: tps.Direction,
    direction: tps.Direction,

    posBuffer: PositionBuffer = undefined,

    // Timestamp of the last attack
    lastAttack: c_int,
    dropRate: f64,
};

pub fn pushToPositionBuffer(b: *PositionBuffer, slot: PositionBufferSlot) void {
    std.debug.assert(b.size < tps.POSITION_BUFFER_SIZE);
    b.buffer[b.size] = slot;
    b.size += 1;
}

pub fn initSprite(model: *const Sprite, self: *Sprite, x: c_int, y: c_int) void {
    // r.c.: 1. I made the model a const pointer.
    // 2. Original C code used a memcpy, hoping the line below is fine.
    self.* = model.*;

    self.x = x;
    self.y = y;
    self.posBuffer.size = 0;

    const ani = gAllocator.create(tps.Animation) catch unreachable;
    tps.copyAnimation(model.ani, ani);
    self.ani = ani;
    ren.updateAnimationOfSprite(self);
}

pub fn createSprite(model: *Sprite, x: c_int, y: c_int) *Sprite {
    const self = gAllocator.create(Sprite) catch unreachable;
    initSprite(model, self, x, y);
    return self;
}
