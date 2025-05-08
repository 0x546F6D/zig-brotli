const std = @import("std");
const brotli = @cImport({
    @cInclude("brotli/decode.h");
    @cInclude("brotli/encode.h");
    @cInclude("brotli/port.h");
    @cInclude("brotli/shared_dictionary.h");
    @cInclude("brotli/types.h");
});

const log = std.log.scoped(.stream);
const ENC_CHUNK_SIZE = 1024;
const DEC_CHUNK_SIZE = 2 * ENC_CHUNK_SIZE;

pub const brotli_decode_result = enum(c_uint) {
    err = brotli.BROTLI_DECODER_RESULT_ERROR,
    success = brotli.BROTLI_DECODER_RESULT_SUCCESS,
    need_more_input = brotli.BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT,
    need_more_output = brotli.BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT,
};

fn getDecodeError(decoder: ?*brotli.BrotliDecoderState) [*c]const u8 {
    return brotli.BrotliDecoderErrorString(brotli.BrotliDecoderGetErrorCode(decoder));
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    // 1. Initialize Brotli decoder
    const decoder = brotli.BrotliDecoderCreateInstance(null, null, null);
    if (decoder == null) {
        log.err("Failed to create Brotli decoder instance", .{});
        return error.EncoderCreationFailed;
    }
    defer brotli.BrotliDecoderDestroyInstance(decoder);

    // Set compression parameters (optional)
    // _ = brotli.BrotliEncoderSetParameter(decoder, brotli.BROTLI_PARAM_QUALITY, 6); // 0-11
    // _ = brotli.BrotliEncoderSetParameter(decoder, brotli.BROTLI_PARAM_LGWIN, 22); // 10-24

    const input = try std.fs.cwd().openFile("compressed.br", .{ .mode = .read_only });
    defer input.close();

    const output = try std.fs.cwd().createFile("output.txt", .{});
    defer output.close();

    var available_in: usize = 0;
    var available_out: usize = DEC_CHUNK_SIZE;
    // var in_buf = try allocator.alloc(u8, ENC_CHUNK_SIZE);
    var in_buf: [ENC_CHUNK_SIZE]u8 = undefined;
    var next_in: [*]const u8 = &in_buf;
    var out_buf: [DEC_CHUNK_SIZE]u8 = undefined;
    var next_out: [*]u8 = &out_buf;
    var total_out: usize = 0;

    var result = brotli_decode_result.need_more_input;

    var ct: usize = 0;
    // 2. Streaming compression loop
    while (ct < 20) {
        log.info("", .{});
        log.info("", .{});
        log.info("================================================================", .{});
        log.info("================================================================", .{});
        log.info("result 1 = {}, ct = {}", .{ result, ct });
        ct += 1;

        switch (result) {
            .need_more_input => {
                available_in = try input.read(&in_buf);
                next_in = &in_buf;
            },
            .need_more_output => {
                const decompressed_size = DEC_CHUNK_SIZE - available_out;
                log.info("need_more_output: decompressed_size = {}", .{decompressed_size});
                if (decompressed_size > 0) {
                    _ = try output.write(out_buf[0..decompressed_size]);
                    // total_out += decompressed_size;
                }
                next_out = &out_buf;
                available_out = DEC_CHUNK_SIZE;
                log.info("need_more_output: total_out = {}", .{total_out});
            },
            .err => {
                log.err("got decoding error: .{s}", .{getDecodeError(decoder)});
                // return error.DecodeError;
                result = brotli_decode_result.need_more_input;
                continue;
            },
            .success => {
                const decompressed_size = DEC_CHUNK_SIZE - available_out;
                log.info("success: decompressed_size = {}", .{decompressed_size});
                if (decompressed_size > 0) {
                    _ = try output.write(out_buf[0..decompressed_size]);
                    // total_out += decompressed_size;
                }
                log.info("success: total_out = {}", .{total_out});
                break;
            },
        }

        log.info("Switch done!", .{});

        // var available_in = try input.read(&in_buf);
        // is_last = available_in < ENC_CHUNK_SIZE;
        // log.info("is_last = {}", .{is_last});

        // var next_in: [*]const u8 = &in_buf;
        // var next_out: [*]u8 = &out_buf;

        result = @enumFromInt(brotli.BrotliDecoderDecompressStream(
            decoder,
            &available_in,
            @ptrCast(&next_in),
            &available_out,
            @ptrCast(&next_out),
            &total_out,
        ));

        // log.info("out_buf 2 = {s}", .{out_buf[0 .. out_buf.len - available_out]});
        log.info("available_out 2 = {}, total_out 2 = {}", .{ available_out, total_out });
        log.info("out_buf.len = {}", .{out_buf.len});
        log.info("result 2 = {}", .{result});
    }

    std.debug.print("DeCompression complete. Total output: {} bytes\n", .{total_out});
}
