const tp = @import("types.zig");
const res = @import("res.zig");
const c = @import("cdefs.zig").c;

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
    shootRange: c_int,
    effectRange: c_int,
    damage: c_int,
    gap: c_int,
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

pub fn initWeapons() void {
    var now: *Weapon = undefined;
    now = &weapons[WEAPON_SWORD];
    initWeapon(now, null, res.RES_SwordFx, null);
    now.damage = 30;
    now.shootRange = 32 * 3;
    now.deathAni.?.scaled = false;
    now.deathAni.?.angle = -1.0;
    now.deathAudio = res.AUDIO_SWORD_HIT;

    now = &weapons[WEAPON_MONSTER_CLAW];
    initWeapon(now, null, res.RES_CLAWFX2, null);
    now.wp = .WEAPON_SWORD_RANGE;
    now.shootRange = 32 * 3 + 16;
    now.damage = 24;
    now.deathAni.?.angle = -1.0;
    now.deathAni.?.at = .AT_CENTER;
    now.deathAudio = res.AUDIO_CLAW_HIT_HEAVY;

    now = &weapons[WEAPON_FIREBALL];
    initWeapon(now, res.RES_Shine, res.RES_HALO_EXPLOSION1, res.RES_FIREBALL);
    now.wp = .WEAPON_GUN_RANGE;
    now.damage = 45;
    now.effectRange = 50;
    now.shootRange = 256;
    now.gap = 180;
    now.deathAni.?.angle = -1.0;
    now.deathAni.?.at = .AT_CENTER;
    now.birthAni.?.duration = 24;
    now.birthAudio = res.AUDIO_SHOOT;
    now.deathAudio = res.AUDIO_FIREBALL_EXP;

    now = &weapons[WEAPON_THUNDER];
    initWeapon(now, res.RES_BLOOD_BOUND, res.RES_Thunder, null);
    now.wp = .WEAPON_SWORD_RANGE;
    now.damage = 80;
    now.shootRange = 128;
    now.gap = 120;
    now.deathAni.?.angle = -1;
    now.deathAni.?.scaled = false;
    now.deathAudio = res.AUDIO_THUNDER;

    now = &weapons[WEAPON_THUNDER_STAFF];
    initWeapon(now, null, res.RES_THUNDER_YELLOW, null);
    now.wp = .WEAPON_SWORD_RANGE;
    now.damage = 50;
    now.shootRange = 128;
    now.gap = 120;
    now.deathAni.?.angle = -1;
    now.deathAni.?.scaled = false;
    now.deathAudio = res.AUDIO_THUNDER;

    now = &weapons[WEAPON_ARROW];
    initWeapon(now, null, res.RES_HALO_EXPLOSION2, res.RES_ARROW);
    now.wp = .WEAPON_GUN_POINT;
    now.gap = 40;
    now.damage = 10;
    now.shootRange = 200;
    now.bulletSpeed = 10;
    now.deathAni.?.angle = -1;
    now.deathAni.?.at = .AT_CENTER;
    now.flyAni.?.scaled = false;
    now.birthAudio = res.AUDIO_LIGHT_SHOOT;
    now.deathAudio = res.AUDIO_ARROW_HIT;

    now = &weapons[WEAPON_POWERFUL_BOW];
    initWeapon(now, null, res.RES_HALO_EXPLOSION2, res.RES_ARROW);
    now.wp = .WEAPON_GUN_POINT;
    now.gap = 60;
    now.damage = 25;
    now.shootRange = 320;
    now.bulletSpeed = 7;
    now.deathAni.?.angle = -1;
    now.deathAni.?.at = .AT_CENTER;
    now.birthAudio = res.AUDIO_LIGHT_SHOOT;
    now.deathAudio = res.AUDIO_ARROW_HIT;
    now.effects[tp.BUFF_ATTACK] = .{ .chance = 0.5, .duration = 240 };

    now = &weapons[WEAPON_MONSTER_CLAW2];
    initWeapon(now, null, res.RES_CLAWFX, null);

    now = &weapons[WEAPON_THROW_AXE];
    initWeapon(now, null, res.RES_CROSS_HIT, res.RES_AXE);
    now.wp = .WEAPON_GUN_POINT;
    now.damage = 12;
    now.shootRange = 160;
    now.bulletSpeed = 10;
    now.flyAni.?.duration = 24;
    now.flyAni.?.angle = -1;
    now.flyAni.?.scaled = false;
    now.deathAni.?.scaled = false;
    now.deathAni.?.at = .AT_CENTER;
    now.birthAudio = res.AUDIO_LIGHT_SHOOT;
    now.deathAudio = res.AUDIO_ARROW_HIT;

    now = &weapons[WEAPON_MANY_AXES];
    initWeapon(now, null, res.RES_CROSS_HIT, res.RES_AXE);
    now.wp = .WEAPON_GUN_POINT_MULTI;
    now.shootRange = 180;
    now.gap = 70;
    now.effectRange = 50;
    now.damage = 50;
    now.bulletSpeed = 4;
    now.flyAni.?.duration = 24;
    now.flyAni.?.angle = -1;
    now.deathAni.?.at = .AT_CENTER;
    now.birthAudio = res.AUDIO_LIGHT_SHOOT;
    now.deathAudio = res.AUDIO_ARROW_HIT;

    now = &weapons[WEAPON_SOLID];
    initWeapon(now, null, res.RES_SOLIDFX, null);
    now.deathAni.?.scaled = false;
    now.deathAni.?.angle = -1;
    now.effects[tp.BUFF_SLOWDOWN] = .{ .chance = 0.3, .duration = 180 };

    now = &weapons[WEAPON_SOLID_GREEN];
    initWeapon(now, null, res.RES_SOLID_GREENFX, null);
    now.shootRange = 96;
    now.deathAni.?.scaled = false;
    now.deathAni.?.angle = -1;
    now.effects[tp.BUFF_SLOWDOWN] = .{ .chance = 0.3, .duration = 180 };

    now = &weapons[WEAPON_SOLID_CLAW];
    initWeapon(now, null, res.RES_SOLID_GREENFX, null);
    now.wp = .WEAPON_SWORD_RANGE;
    now.shootRange = 32 * 3 + 16;
    now.damage = 35;
    now.deathAni.?.scaled = false;
    now.deathAni.?.angle = -1;
    now.deathAudio = res.AUDIO_CLAW_HIT_HEAVY;
    now.effects[tp.BUFF_SLOWDOWN] = .{ .chance = 0.7, .duration = 60 };

    now = &weapons[WEAPON_ICEPICK];
    initWeapon(now, null, res.RES_ICESHATTER, res.RES_ICEPICK);
    now.wp = .WEAPON_GUN_RANGE;
    now.damage = 30;
    now.effectRange = 50;
    now.shootRange = 256;
    now.gap = 180;
    now.bulletSpeed = 8;
    now.deathAni.?.angle = -1;
    now.flyAni.?.scaled = false;
    now.deathAni.?.at = .AT_CENTER;
    now.effects[tp.BUFF_FROZEN] = .{ .chance = 0.2, .duration = 60 };
    now.birthAudio = res.AUDIO_ICE_SHOOT;

    now = &weapons[WEAPON_PURPLE_BALL];
    initWeapon(now, null, res.RES_PURPLE_EXP, res.RES_PURPLE_BALL);
    now.wp = .WEAPON_GUN_RANGE;
    now.damage = 20;
    now.effectRange = 50;
    now.shootRange = 256;
    now.gap = 100;
    now.bulletSpeed = 6;
    now.deathAni.?.angle = -1;
    now.deathAni.?.scaled = false;
    now.flyAni.?.scaled = false;
    now.deathAni.?.at = .AT_CENTER;
    now.birthAudio = res.AUDIO_ICE_SHOOT;
    now.deathAudio = res.AUDIO_ARROW_HIT;

    now = &weapons[WEAPON_PURPLE_STAFF];
    initWeapon(now, null, res.RES_PURPLE_EXP, res.RES_PURPLE_BALL);
    now.wp = .WEAPON_GUN_POINT_MULTI;
    now.damage = 45;
    now.effectRange = 50;
    now.shootRange = 256;
    now.gap = 100;
    now.bulletSpeed = 7;
    now.deathAni.?.angle = -1;
    now.deathAni.?.scaled = false;
    now.flyAni.?.scaled = false;
    now.deathAni.?.at = .AT_CENTER;
    now.birthAudio = res.AUDIO_ICE_SHOOT;
    now.deathAudio = res.AUDIO_ARROW_HIT;

    now = &weapons[WEAPON_HOLY_SWORD];
    initWeapon(now, null, res.RES_GOLDEN_CROSS_HIT, null);
    now.wp = .WEAPON_SWORD_RANGE;
    now.damage = 30;
    now.shootRange = 32 * 4;
    now.effects[tp.BUFF_DEFENCE] = .{ .chance = 0.6, .duration = 180 };

    now = &weapons[WEAPON_ICE_SWORD];
    initWeapon(now, null, res.RES_ICESHATTER, null);
    now.wp = .WEAPON_SWORD_RANGE;
    now.shootRange = 32 * 3 + 16;
    now.damage = 80;
    now.gap = 30;
    now.deathAni.?.angle = -1;
    now.deathAni.?.at = .AT_CENTER;
    now.effects[tp.BUFF_FROZEN] = .{ .chance = 0.6, .duration = 80 };
    now.deathAudio = res.AUDIO_SWORD_HIT;
}
