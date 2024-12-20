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
const baq = @import("boundedarrayqueue.zig");
const c = @import("cdefs.zig").c;
const gAllocator = @import("alloc.zig").gAllocator;

pub const PositionBufferSlot = struct {
    x: c_int,
    y: c_int,
    direction: tps.Direction,
};

pub const PositionBufferQueue = baq.BoundedArrayQueue(
    PositionBufferSlot,
    tps.POSITION_BUFFER_SIZE,
);

pub const Sprite = struct {
    x: c_int,
    y: c_int,
    hp: c_int,
    totalHp: c_int,

    weapon: *wp.Weapon,
    ani: *tps.Animation,
    face: tps.Direction,
    direction: tps.Direction,

    posQueue: PositionBufferQueue = PositionBufferQueue.init(),

    // Timestamp of the last attack
    lastAttack: c_int,
    dropRate: f64,

    pub fn create(model: *Sprite, x: c_int, y: c_int) *Sprite {
        const self = gAllocator.create(Sprite) catch unreachable;
        self.init(model, x, y);
        return self;
    }

    pub fn init(self: *Sprite, model: *const Sprite, x: c_int, y: c_int) void {
        // r.c.: 1. I made the model a const pointer.
        // 2. Original C code used a memcpy, hoping the line below is fine.
        self.* = model.*;

        self.x = x;
        self.y = y;
        self.posQueue = PositionBufferQueue.init();

        const ani = gAllocator.create(tps.Animation) catch unreachable;
        tps.copyAnimation(model.ani, ani);
        self.ani = ani;
        ren.updateAnimationOfSprite(self);
    }
};

pub inline fn pushToPositionBuffer(q: *PositionBufferQueue, slot: PositionBufferSlot) void {
    q.enqueue(slot);
}
