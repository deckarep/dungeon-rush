const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("dungeonrush-zig", "src/main.zig");
    exe.setBuildMode(mode);
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_mixer");
    exe.linkSystemLibrary("SDL2_net");
    exe.linkSystemLibrary("SDL2_image");
    exe.linkSystemLibrary("SDL2_ttf");
    exe.linkSystemLibrary("c");

    const cflags = &[_][]const u8{
        "-std=c99",
        "-pedantic",
        "-Werror",
        "-Wall",
        "-Wextra",
    };

    exe.addCSourceFile("src/main_zig.c", cflags);
    exe.addCSourceFile("src/prng.c", cflags);
    exe.addCSourceFile("src/ui.c", cflags);
    exe.addCSourceFile("src/ai.c", cflags);
    exe.addCSourceFile("src/audio.c", cflags);
    exe.addCSourceFile("src/bullet.c", cflags);
    exe.addCSourceFile("src/game.c", cflags);
    exe.addCSourceFile("src/helper.c", cflags);
    exe.addCSourceFile("src/map.c", cflags);
    exe.addCSourceFile("src/net.c", cflags);
    exe.addCSourceFile("src/player.c", cflags);
    exe.addCSourceFile("src/render.c", cflags);
    exe.addCSourceFile("src/res.c", cflags);
    exe.addCSourceFile("src/sprite.c", cflags);
    exe.addCSourceFile("src/storage.c", cflags);
    exe.addCSourceFile("src/types.c", cflags);
    exe.addCSourceFile("src/weapon.c", cflags);

    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);

    const run = b.step("run", "Run the demo");
    const run_cmd = exe.run();
    run.dependOn(&run_cmd.step);
}
