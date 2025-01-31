const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const brotli_mod = b.addModule("brotli", .{
        .root_source_file = b.path("src/brotli.zig"),
    });

    const brotli_c = b.dependency("brotli.zig", .{
        .target = target,
        .optimize = optimize,
    });
    brotli_mod.linkLibrary(brotli_c.artifact("brotli_lib"));

    const exe = b.addExecutable(.{
        .name = "basic",
        .root_source_file = b.path("examples/basic.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("brotli", brotli_mod);
    b.installArtifact(exe);
}
