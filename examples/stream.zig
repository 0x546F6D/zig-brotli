const Encoder = @import("brotli").Encoder;
const Decoder = @import("brotli").Decoder;

const log = std.log.scoped(.stream_example);
pub const std_options = std.Options{
    .log_level = .info,
};

const CHUNK_SIZE = 4096;

pub fn main() !void {
    // set allocator
    const allocator, const is_dbg = switch (@import("builtin").mode) {
        .Debug, .ReleaseSafe => .{ dbga.allocator(), true },
        .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
    };
    defer if (is_dbg) {
        _ = dbga.deinit();
    };

    const to_encode = @embedFile("brotli_dictionary.c");
    log.info("size to encode: {}", .{to_encode.len});

    // Initialize encoder for streaming and decoder
    var encoder = try Encoder.init(allocator, .{ .process = .stream });
    defer encoder.deinit();
    var decoder = try Decoder.init(allocator, .{});
    defer decoder.deinit();

    var start_idx: usize = 0;
    var stop_idx: usize = @min(to_encode.len, CHUNK_SIZE);

    while (start_idx < to_encode.len) {
        const encoded = try encoder.encode(to_encode[start_idx..stop_idx]);
        defer allocator.free(encoded);

        const decoded = try decoder.decode(encoded);
        defer allocator.free(decoded);

        std.debug.assert(std.mem.eql(u8, to_encode[start_idx..stop_idx], decoded));

        start_idx += CHUNK_SIZE;
        stop_idx = @min(to_encode.len, stop_idx + CHUNK_SIZE);
    }

    std.debug.print(
        \\ -----------------------------------------
        \\Stream Compression/Decompression complete.
        \\Total compressed size: {} bytes
        \\Total decompressed size: {} bytes
    , .{ encoder.total_output_size, decoder.total_output_size });
}

const std = @import("std");
var dbga: std.heap.DebugAllocator(.{}) = .init;
