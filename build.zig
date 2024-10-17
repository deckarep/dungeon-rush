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

    // Any contributors want to help get this building on other platforms and clean this up?
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

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
