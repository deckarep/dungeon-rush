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

const tp = @import("types.zig");
const res = @import("res.zig");
const c = @import("cdefs.zig").c;
const std = @import("std");
const gAllocator = @import("alloc.zig").gAllocator;

pub const WEAPONS_SIZE = 128;
pub const WEAPON_SWORD = 0;
pub const WEAPON_MONSTER_CLAW = 1;
pub const WEAPON_FIREBALL = 2;
pub const WEAPON_THUNDER = 3;
pub const WEAPON_ARROW = 4;
pub const WEAPON_MONSTER_CLAW2 = 5;
pub const WEAPON_THROW_AXE = 6;
pub const WEAPON_MANY_AXES = 7;
pub const WEAPON_SOLID = 8;
pub const WEAPON_SOLID_GREEN = 9;
pub const WEAPON_ICEPICK = 10;
pub const WEAPON_FIRE_SWORD = 11;
pub const WEAPON_ICE_SWORD = 12;
pub const WEAPON_HOLY_SWORD = 13;
pub const WEAPON_PURPLE_BALL = 14;
pub const WEAPON_PURPLE_STAFF = 15;
pub const WEAPON_THUNDER_STAFF = 16;
pub const WEAPON_SOLID_CLAW = 17;
pub const WEAPON_POWERFUL_BOW = 18;

pub var weapons: [WEAPONS_SIZE]Weapon = undefined;
var weaponIndexesUsed: std.ArrayList(usize) = undefined;

pub const WeaponType = enum {
    WEAPON_SWORD_POINT,
    WEAPON_SWORD_RANGE,
    WEAPON_GUN_RANGE,
    WEAPON_GUN_POINT,
    WEAPON_GUN_POINT_MULTI,
};

pub const WeaponBuff = struct {
    chance: f64,
    duration: c_int,
};

pub const Weapon = struct {
    wp: WeaponType,
    // distance for the projectile to fire, too far and it won't fire
    shootRange: c_int,
    // not sure
    effectRange: c_int,
    // how much hp damage
    damage: c_int,
    // fire rate of weapon
    gap: c_int,
    // speed of projectile
    bulletSpeed: c_int,

    birthAni: ?*tp.Animation,
    deathAni: ?*tp.Animation,
    flyAni: ?*tp.Animation,

    birthAudio: c_int,
    deathAudio: c_int,

    effects: [tp.BUFF_END]WeaponBuff,
};

pub fn initWeapon(self: *Weapon, birthTextureId: ?usize, deathTextureId: ?usize, flyTextureId: ?usize) void {
    var birthAni: ?*tp.Animation = null;
    var deathAni: ?*tp.Animation = null;
    var flyAni: ?*tp.Animation = null;

    if (birthTextureId) |btid| {
        birthAni = tp.createAnimation(
            &res.textures[btid],
            null,
            .LOOP_ONCE,
            30,
            0,
            0,
            c.SDL_FLIP_NONE,
            0,
            .AT_CENTER,
        );
    }
    if (deathTextureId) |dtid| {
        deathAni = tp.createAnimation(
            &res.textures[dtid],
            null,
            .LOOP_ONCE,
            30,
            0,
            0,
            c.SDL_FLIP_NONE,
            0,
            .AT_BOTTOM_CENTER,
        );
    }
    if (flyTextureId) |ftid| {
        flyAni = tp.createAnimation(
            &res.textures[ftid],
            null,
            .LOOP_INFI,
            30,
            0,
            0,
            c.SDL_FLIP_NONE,
            0,
            .AT_CENTER,
        );
    }

    self.* = Weapon{
        .wp = .WEAPON_SWORD_POINT,
        .shootRange = 32 * 2,
        .effectRange = 40,
        .damage = 10,
        .gap = 60,
        .bulletSpeed = 6,
        .birthAni = birthAni,
        .deathAni = deathAni,
        .flyAni = flyAni,
        .birthAudio = -1,
        .deathAudio = 5,
        .effects = undefined,
    };
}

pub fn destroyWeapons() void {
    defer weaponIndexesUsed.deinit();

    for (weaponIndexesUsed.items) |i| {
        const wp = weapons[i];

        if (wp.birthAni) |ba| {
            gAllocator.destroy(ba);
        }
        if (wp.deathAni) |da| {
            gAllocator.destroy(da);
        }
        if (wp.flyAni) |fa| {
            gAllocator.destroy(fa);
        }
    }
}

pub fn initWeapons() !void {
    // r.c. - added by me.
    // This ArrayList is for a little extra book-keeping of the weapons initialized.
    // I need to destroy all their respective dynamically allocated *Animations.
    // Also, the weapons array data may not be contiguous, so just tracking for the
    // sole purpose of cleanup.

    // I will go back and make this code more straightforward.
    weaponIndexesUsed = std.ArrayList(usize).init(gAllocator);

    var curWep: *Weapon = undefined;
    curWep = &weapons[WEAPON_SWORD];
    try weaponIndexesUsed.append(WEAPON_SWORD);
    initWeapon(curWep, null, res.RES_SwordFx, null);
    curWep.damage = 30;
    curWep.shootRange = 32 * 3;
    curWep.deathAni.?.scaled = false;
    curWep.deathAni.?.angle = -1.0;
    curWep.deathAudio = res.AUDIO_SWORD_HIT;

    curWep = &weapons[WEAPON_MONSTER_CLAW];
    try weaponIndexesUsed.append(WEAPON_MONSTER_CLAW);
    initWeapon(curWep, null, res.RES_CLAWFX2, null);
    curWep.wp = .WEAPON_SWORD_RANGE;
    curWep.shootRange = 32 * 3 + 16;
    curWep.damage = 24;
    curWep.deathAni.?.angle = -1.0;
    curWep.deathAni.?.at = .AT_CENTER;
    curWep.deathAudio = res.AUDIO_CLAW_HIT_HEAVY;

    curWep = &weapons[WEAPON_FIREBALL];
    try weaponIndexesUsed.append(WEAPON_FIREBALL);
    initWeapon(curWep, res.RES_Shine, res.RES_HALO_EXPLOSION1, res.RES_FIREBALL);
    curWep.wp = .WEAPON_GUN_RANGE;
    curWep.damage = 45;
    curWep.effectRange = 50;
    curWep.shootRange = 256;
    curWep.gap = 180;
    curWep.deathAni.?.angle = -1.0;
    curWep.deathAni.?.at = .AT_CENTER;
    curWep.birthAni.?.duration = 24;
    curWep.birthAudio = res.AUDIO_SHOOT;
    curWep.deathAudio = res.AUDIO_FIREBALL_EXP;

    curWep = &weapons[WEAPON_THUNDER];
    try weaponIndexesUsed.append(WEAPON_THUNDER);
    initWeapon(curWep, res.RES_BLOOD_BOUND, res.RES_Thunder, null);
    curWep.wp = .WEAPON_SWORD_RANGE;
    curWep.damage = 80;
    curWep.shootRange = 128;
    curWep.gap = 120;
    curWep.deathAni.?.angle = -1;
    curWep.deathAni.?.scaled = false;
    curWep.deathAudio = res.AUDIO_THUNDER;

    curWep = &weapons[WEAPON_THUNDER_STAFF];
    try weaponIndexesUsed.append(WEAPON_THUNDER_STAFF);
    initWeapon(curWep, null, res.RES_THUNDER_YELLOW, null);
    curWep.wp = .WEAPON_SWORD_RANGE;
    curWep.damage = 50;
    curWep.shootRange = 128;
    curWep.gap = 120;
    curWep.deathAni.?.angle = -1;
    curWep.deathAni.?.scaled = false;
    curWep.deathAudio = res.AUDIO_THUNDER;

    curWep = &weapons[WEAPON_ARROW];
    try weaponIndexesUsed.append(WEAPON_ARROW);
    initWeapon(curWep, null, res.RES_HALO_EXPLOSION2, res.RES_ARROW);
    curWep.wp = .WEAPON_GUN_POINT;
    curWep.gap = 40;
    curWep.damage = 10;
    curWep.shootRange = 200;
    curWep.bulletSpeed = 10;
    curWep.deathAni.?.angle = -1;
    curWep.deathAni.?.at = .AT_CENTER;
    curWep.flyAni.?.scaled = false;
    curWep.birthAudio = res.AUDIO_BOW_FIRE;
    curWep.deathAudio = res.AUDIO_BOW_HIT;

    curWep = &weapons[WEAPON_POWERFUL_BOW];
    try weaponIndexesUsed.append(WEAPON_POWERFUL_BOW);
    initWeapon(curWep, null, res.RES_HALO_EXPLOSION2, res.RES_ARROW);
    curWep.wp = .WEAPON_GUN_POINT;
    curWep.gap = 60;
    curWep.damage = 25;
    curWep.shootRange = 320;
    curWep.bulletSpeed = 7;
    curWep.deathAni.?.angle = -1;
    curWep.deathAni.?.at = .AT_CENTER;
    curWep.birthAudio = res.AUDIO_BOW_FIRE;
    curWep.deathAudio = res.AUDIO_BOW_HIT;
    curWep.effects[tp.BUFF_ATTACK] = .{ .chance = 0.5, .duration = 240 };

    curWep = &weapons[WEAPON_MONSTER_CLAW2];
    try weaponIndexesUsed.append(WEAPON_MONSTER_CLAW2);
    initWeapon(curWep, null, res.RES_CLAWFX, null);

    curWep = &weapons[WEAPON_THROW_AXE];
    try weaponIndexesUsed.append(WEAPON_THROW_AXE);
    initWeapon(curWep, null, res.RES_CROSS_HIT, res.RES_AXE);
    curWep.wp = .WEAPON_GUN_POINT;
    curWep.damage = 12;
    curWep.shootRange = 160;
    curWep.bulletSpeed = 10;
    curWep.flyAni.?.duration = 24;
    curWep.flyAni.?.angle = -1;
    curWep.flyAni.?.scaled = false;
    curWep.deathAni.?.scaled = false;
    curWep.deathAni.?.at = .AT_CENTER;
    curWep.birthAudio = res.AUDIO_AXE_FLY; //res.AUDIO_LIGHT_SHOOT;
    curWep.deathAudio = res.AUDIO_ARROW_HIT;

    curWep = &weapons[WEAPON_MANY_AXES];
    try weaponIndexesUsed.append(WEAPON_MANY_AXES);
    initWeapon(curWep, null, res.RES_CROSS_HIT, res.RES_AXE);
    curWep.wp = .WEAPON_GUN_POINT_MULTI;
    curWep.shootRange = 180;
    curWep.gap = 70;
    curWep.effectRange = 50;
    curWep.damage = 50;
    curWep.bulletSpeed = 4;
    curWep.flyAni.?.duration = 24;
    curWep.flyAni.?.angle = -1;
    curWep.deathAni.?.at = .AT_CENTER;
    curWep.birthAudio = res.AUDIO_AXE_FLY; //res.AUDIO_LIGHT_SHOOT;res.AUDIO_LIGHT_SHOOT;
    curWep.deathAudio = res.AUDIO_ARROW_HIT;

    curWep = &weapons[WEAPON_SOLID];
    try weaponIndexesUsed.append(WEAPON_SOLID);
    initWeapon(curWep, null, res.RES_SOLIDFX, null);
    curWep.deathAni.?.scaled = false;
    curWep.deathAni.?.angle = -1;
    curWep.effects[tp.BUFF_SLOWDOWN] = .{ .chance = 0.3, .duration = 180 };

    curWep = &weapons[WEAPON_SOLID_GREEN];
    try weaponIndexesUsed.append(WEAPON_SOLID_GREEN);
    initWeapon(curWep, null, res.RES_SOLID_GREENFX, null);
    curWep.shootRange = 96;
    curWep.deathAni.?.scaled = false;
    curWep.deathAni.?.angle = -1;
    curWep.effects[tp.BUFF_SLOWDOWN] = .{ .chance = 0.3, .duration = 180 };

    curWep = &weapons[WEAPON_SOLID_CLAW];
    try weaponIndexesUsed.append(WEAPON_SOLID_CLAW);
    initWeapon(curWep, null, res.RES_SOLID_GREENFX, null);
    curWep.wp = .WEAPON_SWORD_RANGE;
    curWep.shootRange = 32 * 3 + 16;
    curWep.damage = 35;
    curWep.deathAni.?.scaled = false;
    curWep.deathAni.?.angle = -1;
    curWep.deathAudio = res.AUDIO_CLAW_HIT_HEAVY;
    curWep.effects[tp.BUFF_SLOWDOWN] = .{ .chance = 0.7, .duration = 60 };

    curWep = &weapons[WEAPON_ICEPICK];
    try weaponIndexesUsed.append(WEAPON_ICEPICK);
    initWeapon(curWep, null, res.RES_ICESHATTER, res.RES_ICEPICK);
    curWep.wp = .WEAPON_GUN_RANGE;
    curWep.damage = 30;
    curWep.effectRange = 50;
    curWep.shootRange = 256;
    curWep.gap = 180;
    curWep.bulletSpeed = 8;
    curWep.deathAni.?.angle = -1;
    curWep.flyAni.?.scaled = false;
    curWep.deathAni.?.at = .AT_CENTER;
    curWep.effects[tp.BUFF_FROZEN] = .{ .chance = 0.2, .duration = 60 };
    curWep.birthAudio = res.AUDIO_ICE_SHOOT;

    curWep = &weapons[WEAPON_PURPLE_BALL];
    try weaponIndexesUsed.append(WEAPON_PURPLE_BALL);
    initWeapon(curWep, null, res.RES_PURPLE_EXP, res.RES_PURPLE_BALL);
    curWep.wp = .WEAPON_GUN_RANGE;
    curWep.damage = 20;
    curWep.effectRange = 50;
    curWep.shootRange = 256;
    curWep.gap = 100;
    curWep.bulletSpeed = 6;
    curWep.deathAni.?.angle = -1;
    curWep.deathAni.?.scaled = false;
    curWep.flyAni.?.scaled = false;
    curWep.deathAni.?.at = .AT_CENTER;
    curWep.birthAudio = res.AUDIO_ICE_SHOOT;
    curWep.deathAudio = res.AUDIO_ARROW_HIT;

    curWep = &weapons[WEAPON_PURPLE_STAFF];
    try weaponIndexesUsed.append(WEAPON_PURPLE_STAFF);
    initWeapon(curWep, null, res.RES_PURPLE_EXP, res.RES_PURPLE_FIRE_BALL);
    curWep.wp = .WEAPON_GUN_POINT_MULTI;
    curWep.damage = 45;
    curWep.effectRange = 50;
    curWep.shootRange = 256;
    curWep.gap = 100;
    curWep.bulletSpeed = 7;
    curWep.deathAni.?.angle = -1;
    curWep.deathAni.?.scaled = false;
    curWep.flyAni.?.scaled = false;
    curWep.deathAni.?.at = .AT_CENTER;
    curWep.birthAudio = res.AUDIO_ICE_SHOOT;
    curWep.deathAudio = res.AUDIO_ARROW_HIT;

    curWep = &weapons[WEAPON_HOLY_SWORD];
    try weaponIndexesUsed.append(WEAPON_HOLY_SWORD);
    initWeapon(curWep, null, res.RES_GOLDEN_CROSS_HIT, null);
    curWep.wp = .WEAPON_SWORD_RANGE;
    curWep.damage = 30;
    curWep.shootRange = 32 * 4;
    curWep.effects[tp.BUFF_DEFENCE] = .{ .chance = 0.6, .duration = 180 };

    curWep = &weapons[WEAPON_ICE_SWORD];
    try weaponIndexesUsed.append(WEAPON_ICE_SWORD);
    initWeapon(curWep, null, res.RES_ICESHATTER, null);
    curWep.wp = .WEAPON_SWORD_RANGE;
    curWep.shootRange = 32 * 3 + 16;
    curWep.damage = 80;
    curWep.gap = 30;
    curWep.deathAni.?.angle = -1;
    curWep.deathAni.?.at = .AT_CENTER;
    curWep.effects[tp.BUFF_FROZEN] = .{ .chance = 0.6, .duration = 80 };
    curWep.deathAudio = res.AUDIO_SWORD_HIT;
}
