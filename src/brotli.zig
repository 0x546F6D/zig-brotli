const std = @import("std");

pub const br_c = @cImport({
    @cInclude("brotli/decode.h");
    @cInclude("brotli/encode.h");
    @cInclude("brotli/port.h");
    @cInclude("brotli/shared_dictionary.h");
    @cInclude("brotli/types.h");
});

pub const BrotliError = error{
    EncodeError,
    DecodeError,
};

/// brotli encode string
pub fn encode(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var encoded_size = input.len;
    const encoded_buffer = try allocator.alloc(u8, encoded_size);
    defer allocator.free(encoded_buffer);

    // BROTLI_ENC_API BROTLI_BOOL BrotliEncoderCompress(
    //     int quality,
    //     int lgwin,
    //     BrotliEncoderMode mode,
    //     size_t input_size,
    //     const uint8_t input_buffer[BROTLI_ARRAY_PARAM(input_size)],
    //     size_t* encoded_size,
    //     uint8_t encoded_buffer[BROTLI_ARRAY_PARAM(*encoded_size)]);
    const result = br_c.BrotliEncoderCompress(
        br_c.BROTLI_DEFAULT_QUALITY,
        br_c.BROTLI_DEFAULT_WINDOW,
        br_c.BROTLI_DEFAULT_MODE,
        input.len,
        input.ptr,
        @ptrCast(&encoded_size),
        @ptrCast(encoded_buffer),
    );

    if (result == br_c.BROTLI_TRUE) {
        return try allocator.dupe(u8, encoded_buffer[0..encoded_size]);
    } else {
        return BrotliError.EncodeError;
    }
}

/// brotli decode string
pub fn decode(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    // 10*encoded size should be enough for the decoded buffer
    var decoded_size = input.len * 10;
    var decoded_buffer = try allocator.alloc(u8, decoded_size);

    // BROTLI_DEC_API BrotliDecoderResult BrotliDecoderDecompress(
    //     size_t encoded_size,
    //     const uint8_t encoded_buffer[BROTLI_ARRAY_PARAM(encoded_size)],
    //     size_t* decoded_size,
    //     uint8_t decoded_buffer[BROTLI_ARRAY_PARAM(*decoded_size)]);
    var result = br_c.BrotliDecoderDecompress(
        input.len,
        input.ptr,
        @ptrCast(&decoded_size),
        @ptrCast(decoded_buffer),
    );

    if (result != br_c.BROTLI_DECODER_RESULT_SUCCESS) {
        // let's try again, with an even bigger buffer: 20*
        allocator.free(decoded_buffer);
        decoded_size = input.len * 20;
        decoded_buffer = try allocator.alloc(u8, decoded_size);

        result = br_c.BrotliDecoderDecompress(
            input.len,
            input.ptr,
            @ptrCast(&decoded_size),
            @ptrCast(decoded_buffer),
        );
    }

    defer allocator.free(decoded_buffer);
    if (result == br_c.BROTLI_DECODER_RESULT_SUCCESS) {
        return try allocator.dupe(u8, decoded_buffer[0..decoded_size]);
    } else {
        return BrotliError.DecodeError;
    }
}
