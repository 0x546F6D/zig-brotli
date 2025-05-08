const Encoder = @import("brotli").Encoder;
const Decoder = @import("brotli").Decoder;

const log = std.log.scoped(.mem_to_mem_example);
pub const std_options = std.Options{
    .log_level = .info,
};

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

    // Initialize encoder for one_shot processing and decoder
    var encoder = try Encoder.init(allocator, .{ .window = 29 });
    defer encoder.deinit();
    var decoder = try Decoder.init(allocator, .{ .use_large_window = true });
    defer decoder.deinit();

    const encoded = try encoder.encode(to_encode);
    defer allocator.free(encoded);
    log.info("size of encoded: {}", .{encoded.len});

    const decoded = try decoder.decode(encoded);
    defer allocator.free(decoded);
    log.info("size of decoded: {}", .{decoded.len});
}

const std = @import("std");
var dbga: std.heap.DebugAllocator(.{}) = .init;
