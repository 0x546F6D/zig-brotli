const std = @import("std");
const brotli = @cImport({
    @cInclude("brotli/decode.h");
    @cInclude("brotli/encode.h");
    @cInclude("brotli/port.h");
    @cInclude("brotli/shared_dictionary.h");
    @cInclude("brotli/types.h");
});

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const log = std.log.scoped(.stream);
const ENC_CHUNK_SIZE = 1024;
const DEC_CHUNK_SIZE = 2 * ENC_CHUNK_SIZE;

pub const brotli_decode_result = enum(c_uint) {
    err = brotli.BROTLI_DECODER_RESULT_ERROR,
    success = brotli.BROTLI_DECODER_RESULT_SUCCESS,
    need_more_input = brotli.BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT,
    need_more_output = brotli.BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT,
};

fn getError(decoder: ?*brotli.BrotliDecoderState) [*c]const u8 {
    return brotli.BrotliDecoderErrorString(brotli.BrotliDecoderGetErrorCode(decoder));
}

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

    const enc_comp_input = try std.fs.cwd().openFile("compressed_2.br", .{ .mode = .read_only });
    defer enc_comp_input.close();
    var enc_comp_buf: [4 * ENC_CHUNK_SIZE]u8 = undefined;
    const enc_comp_in = try enc_comp_input.read(&enc_comp_buf);
    var enc_comp_idx: usize = 0;
    log.info("enc_in: {}", .{enc_comp_in});

    const input = try std.fs.cwd().openFile("input.txt", .{ .mode = .read_only });
    defer input.close();

    const output = try std.fs.cwd().createFile("compressed.br", .{});
    defer output.close();

    var enc_in_buf: [DEC_CHUNK_SIZE]u8 = undefined;
    var enc_out_buf: [DEC_CHUNK_SIZE]u8 = undefined;
    var total_out: usize = 0;
    var is_last = false;

    // 1.b setup decoder
    const decoder = brotli.BrotliDecoderCreateInstance(null, null, null);
    if (decoder == null) {
        std.debug.print("Failed to create Brotli decoder instance\n", .{});
        return error.EncoderCreationFailed;
    }
    defer brotli.BrotliDecoderDestroyInstance(decoder);

    const dec_out = try std.fs.cwd().createFile("output.txt", .{});
    defer dec_out.close();

    var dec_buf: [DEC_CHUNK_SIZE]u8 = undefined;
    var dec_total_out: usize = 0;

    // 2. Streaming compression loop
    while (!is_last) {
        var available_in = try input.read(&enc_in_buf);
        is_last = available_in < DEC_CHUNK_SIZE;
        log.info("available_in = {}, is_last = {}", .{ available_in, is_last });
        // log.info("\nin_buf:{s}\n", .{in_buf});

        var next_in: [*]const u8 = &enc_in_buf;
        var available_out: usize = DEC_CHUNK_SIZE;
        var next_out: [*]u8 = &enc_out_buf;

        const result = brotli.BrotliEncoderCompressStream(
            encoder,
            if (is_last) brotli.BROTLI_OPERATION_FINISH else brotli.BROTLI_OPERATION_FLUSH,
            &available_in,
            @ptrCast(&next_in),
            &available_out,
            @ptrCast(&next_out),
            &total_out,
        );

        if (result == brotli.BROTLI_FALSE) {
            std.debug.print("Brotli compression failed\n", .{});
            break;
        }

        // Write compressed data to output file
        const compressed_size = DEC_CHUNK_SIZE - available_out;
        log.info("compressed_size = {}", .{compressed_size});

        log.info("enc_comp_buf = {s}", .{enc_comp_buf[enc_comp_idx .. enc_comp_idx + compressed_size]});
        if (std.mem.eql(u8, enc_out_buf[0..compressed_size], enc_comp_buf[enc_comp_idx .. enc_comp_idx + compressed_size])) {
            log.info("OUT_BUF == ENC_BUFF", .{});
        } else log.info("OUT_BUF NOT EQL TO ENC_BUFF", .{});
        enc_comp_idx += compressed_size;

        if (compressed_size > 0) {
            _ = try output.write(enc_out_buf[0..compressed_size]);
            log.info("enc_out_buf = {s}", .{enc_out_buf[0..compressed_size]});

            var dec_available_in = compressed_size;
            var dec_next_in: [*]const u8 = undefined;
            var dec_available_out: usize = DEC_CHUNK_SIZE;
            var dec_next_out: [*]u8 = &dec_buf;

            var desc = try allocator.alloc(u8, compressed_size);
            @memcpy(desc, enc_out_buf[0..compressed_size]);
            dec_next_in = @ptrCast(&desc);

            const dec_result: brotli_decode_result = @enumFromInt(brotli.BrotliDecoderDecompressStream(
                decoder,
                &dec_available_in,
                @ptrCast(&desc),
                &dec_available_out,
                @ptrCast(&dec_next_out),
                &dec_total_out,
            ));

            log.info("===========================", .{});
            log.info("===========================", .{});
            // log.info("dec_buf = {s}", .{dec_buf[0 .. DEC_CHUNK_SIZE - dec_available_out]});
            log.info("dec_result 1 = {}, dec_available_out = {}, dec_total_out = {}", .{
                dec_result,
                dec_available_in,
                dec_total_out,
            });

            if (dec_result == brotli_decode_result.need_more_input) {
                //
                _ = try dec_out.write(dec_buf[0 .. DEC_CHUNK_SIZE - dec_available_out]);
            }
        }
    }

    std.debug.print("Compression complete. Total output: {} bytes\n", .{total_out});
}
