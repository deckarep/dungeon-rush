const std = @import("std");
const tps = @import("types.zig");
const wp = @import("weapons.zig");
const ren = @import("render.zig");
const c = @import("cdefs.zig").c;

pub const PositionBufferSlot = struct {
    x: c_int,
    y: c_int,
    direction: tps.Direction,
};

pub const PositionBuffer = struct {
    buffer: [tps.POSITION_BUFFER_SIZE]PositionBufferSlot,
    size: c_int,
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
    const sz: usize = @intCast(b.size);
    b.buffer[sz] = slot;
    b.size += 1;
}

pub fn initSprite(model: *const Sprite, self: *Sprite, x: c_int, y: c_int) void {
    // r.c.: 1. I made the model a const pointer.
    // 2. Original C code used a memcpy, hoping the line below is fine.
    self.* = model.*;

    self.x = x;
    self.y = y;
    self.posBuffer.size = 0;
    const ani: *tps.Animation = @alignCast(@ptrCast(c.malloc(@sizeOf(tps.Animation))));
    tps.copyAnimation(model.ani, ani);
    self.ani = ani;
    ren.updateAnimationOfSprite(self);
}

pub fn createSprite(model: *Sprite, x: c_int, y: c_int) *Sprite {
    const self: *Sprite = @alignCast(@ptrCast(c.malloc(@sizeOf(Sprite))));
    initSprite(model, self, x, y);
    return self;
}
