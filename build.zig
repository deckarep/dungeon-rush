const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "dungeonrush-zig",
        .root_source_file = b.path("zsrc/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const macos_arm64_homebrew_path = "/opt/homebrew/opt/";
    exe.addIncludePath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "sdl2/include/SDL2" });
    exe.addLibraryPath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "sdl2/lib" });
    exe.linkSystemLibrary("SDL2");

    exe.addIncludePath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "sdl2_mixer/include/SDL2" });
    exe.addLibraryPath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "sdl2_mixer/lib" });
    exe.linkSystemLibrary("SDL2_mixer");

    exe.addIncludePath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "sdl2_image/include/SDL2" });
    exe.addLibraryPath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "sdl2_image/lib" });
    exe.linkSystemLibrary("SDL2_image");

    exe.addIncludePath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "sdl2_ttf/include/SDL2" });
    exe.addLibraryPath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "sdl2_ttf/lib" });
    exe.linkSystemLibrary("SDL2_ttf");

    exe.addIncludePath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "sdl2_net/include/SDL2" });
    exe.addLibraryPath(.{ .cwd_relative = macos_arm64_homebrew_path ++ "sdl2_net/lib" });
    exe.linkSystemLibrary("SDL2_net");

    exe.linkSystemLibrary("c");

    // const cflags = &[_][]const u8{
    //     "-std=c99",
    //     //"-pedantic", <-- rc: once all C code is removed and migrated to Zig, this shouldn't break.
    //     "-Werror",
    //     "-Wall",
    //     "-Wextra",
    // };

    // exe.addCSourceFiles(.{
    //     .files = &.{
    //         "src/ui.c",
    //         "src/ai.c",
    //         "src/audio.c",
    //         "src/bullet.c",
    //         "src/game.c",
    //         "src/helper.c",
    //         "src/map.c",
    //         "src/net.c",
    //         "src/player.c",
    //         "src/render.c",
    //         "src/res.c",
    //         "src/sprite.c",
    //         "src/storage.c",
    //         "src/types.c",
    //         "src/weapon.c",
    //     },
    //     .flags = cflags,
    // });

    // Needed for Zig files to find C header files.
    //exe.addIncludePath(b.path("src"));

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
