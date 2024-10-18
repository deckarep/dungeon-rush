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
const wp = @import("weapons.zig");
const pl = @import("player.zig");
const tps = @import("types.zig");
const c = @import("cdefs.zig").c;

pub const Bullet = struct {
    parent: *wp.Weapon,
    x: c_int,
    y: c_int,
    team: c_int,
    owner: ?*pl.Snake,
    rad: f64,
    ani: *tps.Animation,
};

pub fn createBullet(
    owner: *pl.Snake,
    parent: *wp.Weapon,
    x: c_int,
    y: c_int,
    rad: f64,
    team: c_int,
    ani: *tps.Animation,
) *Bullet {
    const bullet: *Bullet = @alignCast(@ptrCast(c.malloc(@sizeOf(Bullet))));
    bullet.* = .{
        .parent = parent,
        .x = x,
        .y = y,
        .team = team,
        .owner = owner,
        .rad = rad,
        .ani = @alignCast(@ptrCast(c.malloc(@sizeOf(tps.Animation)))),
    };
    tps.copyAnimation(ani, bullet.ani);
    bullet.ani.x = x;
    bullet.ani.y = y;
    bullet.ani.angle = rad * 180 / std.math.pi;
    return bullet;
}

pub fn moveBullet(bullet: *Bullet) void {
    const speed: f64 = @floatFromInt(bullet.parent.bulletSpeed);
    bullet.x += @intFromFloat(@cos(bullet.rad) * speed);
    bullet.y += @intFromFloat(@sin(bullet.rad) * speed);
    bullet.ani.x = bullet.x;
    bullet.ani.y = bullet.y;
}

pub fn destroyBullet(bullet: *Bullet) void {
    c.free(bullet);
}