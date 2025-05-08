const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const brotli_mod = b.addModule("brotli", .{
        .root_source_file = b.path("src/brotli.zig"),
    });

    const brotli_c = b.dependency("brotli_build", .{
        .target = target,
        .optimize = optimize,
    });
    brotli_mod.linkLibrary(brotli_c.artifact("brotli_lib"));

    const build_basic = b.option(bool, "mem", "Build basic example executable (default:false)") orelse false;
    if (build_basic) {
        const exe = b.addExecutable(.{
            .name = "mem",
            .root_source_file = b.path("examples/mem_to_mem.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("brotli", brotli_mod);
        b.installArtifact(exe);
    }

    const build_encode = b.option(bool, "enc", "Build stream example executable (default:false)") orelse false;
    if (build_encode) {
        const exe = b.addExecutable(.{
            .name = "encode",
            .root_source_file = b.path("examples/stream_enc.zig"),
            .target = target,
            .optimize = optimize,
        });
        // exe.root_module.addImport("brotli", brotli_mod);
        exe.linkLibrary(brotli_c.artifact("brotli_lib"));
        b.installArtifact(exe);
    }

    const build_dec = b.option(bool, "dec", "Build decode example executable (default:false)") orelse false;
    if (build_dec) {
        const exe = b.addExecutable(.{
            .name = "decode",
            .root_source_file = b.path("examples/stream_dec.zig"),
            .target = target,
            .optimize = optimize,
        });
        // exe.root_module.addImport("brotli", brotli_mod);
        exe.linkLibrary(brotli_c.artifact("brotli_lib"));
        b.installArtifact(exe);
    }

    const build_stream = b.option(bool, "stream", "Build stream example executable (default:false)") orelse false;
    if (build_stream) {
        const exe = b.addExecutable(.{
            .name = "stream",
            .root_source_file = b.path("examples/stream.zig"),
            .target = target,
            .optimize = optimize,
        });
        // exe.root_module.addImport("brotli", brotli_mod);
        exe.root_module.addImport("brotli", brotli_mod);
        // exe.linkLibrary(brotli_c.artifact("brotli_lib"));
        b.installArtifact(exe);
    }
}
