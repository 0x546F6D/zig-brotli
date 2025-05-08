const std = @import("std");
const brotli = @cImport({
    @cInclude("brotli/decode.h");
    @cInclude("brotli/encode.h");
    @cInclude("brotli/port.h");
    @cInclude("brotli/shared_dictionary.h");
    @cInclude("brotli/types.h");
});

const log = std.log.scoped(.encode);
const CHUNK_SIZE = 2048;

pub fn main() !void {
    // 1. Initialize Brotli encoder
    const encoder = brotli.BrotliEncoderCreateInstance(null, null, null);
    if (encoder == null) {
        std.debug.print("Failed to create Brotli encoder instance\n", .{});
        return error.EncoderCreationFailed;
    }
    defer brotli.BrotliEncoderDestroyInstance(encoder);

    // Set compression parameters (optional)
    _ = brotli.BrotliEncoderSetParameter(encoder, brotli.BROTLI_PARAM_QUALITY, 6); // 0-11
    _ = brotli.BrotliEncoderSetParameter(encoder, brotli.BROTLI_PARAM_LGWIN, 22); // 10-24

    const input = try std.fs.cwd().openFile("input.txt", .{ .mode = .read_only });
    defer input.close();

    const output = try std.fs.cwd().createFile("compressed.br", .{});
    defer output.close();

    var in_buf: [CHUNK_SIZE]u8 = undefined;
    var out_buf: [CHUNK_SIZE]u8 = undefined;
    var total_out: usize = 0;
    var is_last = false;

    // 2. Streaming compression loop
    while (!is_last) {
        var available_in = try input.read(&in_buf);
        is_last = available_in < CHUNK_SIZE;
        // is_last = available_in == 0;
        log.info("available_in = {}, is_last = {}", .{ available_in, is_last });
        // log.info("\nin_buf:{s}\n", .{in_buf[0..available_in]});

        var next_in: [*]const u8 = &in_buf;
        var available_out: usize = CHUNK_SIZE;
        var next_out: [*]u8 = &out_buf;

        const result = brotli.BrotliEncoderCompressStream(
            encoder,
            // if (is_last) brotli.BROTLI_OPERATION_FINISH else brotli.BROTLI_OPERATION_PROCESS,
            if (is_last) brotli.BROTLI_OPERATION_FINISH else brotli.BROTLI_OPERATION_FLUSH,
            // brotli.BROTLI_OPERATION_FINISH,
            &available_in,
            @ptrCast(&next_in),
            &available_out,
            @ptrCast(&next_out),
            &total_out,
        );
        // if (is_last) brotli.BrotliEncoderWriteMetadata(
        //     encoder,
        //     &available_out,
        //     @ptrCast(&next_out),
        //     null,
        // );
        if (result == brotli.BROTLI_FALSE) {
            std.debug.print("Brotli compression failed\n", .{});
            break;
        }

        // Write compressed data to output file
        const compressed_size = CHUNK_SIZE - available_out;
        log.info("compressed_size = {}", .{compressed_size});
        if (compressed_size > 0) {
            _ = try output.write(out_buf[0..compressed_size]);
            log.info("out =\n{s}", .{out_buf[0..compressed_size]});
        }

        // If there's more output pending even after filling our buffer
        // while (brotli.BrotliEncoderHasMoreOutput(encoder) == brotli.BROTLI_TRUE) {
        // log.info("Inside BrotliEncoderHasMoreOutput", .{});
        // available_out = CHUNK_SIZE;
        // next_out = &out_buf;
        // _ = brotli.BrotliEncoderCompressStream(
        //     encoder,
        //     brotli.BROTLI_OPERATION_FLUSH,
        //     &available_in,
        //     @ptrCast(&next_in),
        //     &available_out,
        //     @ptrCast(&next_out),
        //     &total_out,
        // );
        //
        // const flush_size = CHUNK_SIZE - available_out;
        // log.info("flush_size = {}", .{flush_size});
        // if (flush_size > 0) {
        //     _ = try output.write(out_buf[0..flush_size]);
        //     log.info("flush =\n{s}", .{out_buf[0..flush_size]});
        // }
        // }
    }

    std.debug.print("Compression complete. Total output: {} bytes\n", .{total_out});
}
