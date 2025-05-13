const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add Brotli module
    const brotli_mod = b.addModule("brotli", .{
        .root_source_file = b.path("src/brotli.zig"),
    });

    const brotli_c = b.dependency("brotli_build", .{
        .target = target,
        .optimize = optimize,
    });
    brotli_mod.linkLibrary(brotli_c.artifact("brotli_lib"));
    brotli_mod.addImport("c", brotli_c.module("c_api"));

    // Build mem to mem one shot example
    const build_mem = b.option(bool, "mem", "Build basic example executable (default:false)") orelse false;
    if (build_mem) {
        const exe = b.addExecutable(.{
            .name = "mem",
            .root_source_file = b.path("examples/mem_to_mem.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("brotli", brotli_mod);
        b.installArtifact(exe);
    }

    // Build streaming example
    const build_stream = b.option(bool, "stream", "Build stream example executable (default:false)") orelse false;
    if (build_stream) {
        const exe = b.addExecutable(.{
            .name = "stream",
            .root_source_file = b.path("examples/stream.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("brotli", brotli_mod);
        b.installArtifact(exe);
    }
}
