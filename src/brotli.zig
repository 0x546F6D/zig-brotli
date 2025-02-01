const std = @import("std");

pub const br_c = @cImport({
    @cInclude("brotli/decode.h");
    @cInclude("brotli/encode.h");
    @cInclude("brotli/port.h");
    @cInclude("brotli/shared_dictionary.h");
    @cInclude("brotli/types.h");
});

const log = std.log.scoped(.brotli);
const Brotli = @This();

settings: Settings,

pub const Settings = struct {
    encode_quality: c_int = br_c.BROTLI_DEFAULT_QUALITY,
    encode_window: c_int = br_c.BROTLI_DEFAULT_WINDOW,
    encode_mode: brotli_mode = .text,
    /// Brotli cannot give the size of the decoded buffer before decoding:
    /// - so u have to try different with different output buffer sizes
    /// - the size of the output buffer will be calculated by multiplying
    /// the size of the input buffer with the values in this field.
    decode_size_mult: []const u8 = &[_]u8{ 5, 10, 20 },
};
// var decode_size_mult = [_]u8{ 5, 10, 20 };

pub const brotli_mode = enum(c_uint) {
    generic = br_c.BROTLI_MODE_GENERIC,
    text = br_c.BROTLI_MODE_TEXT,
    font = br_c.BROTLI_MODE_FONT,
};

pub const brotli_decode_result = enum(c_uint) {
    err = br_c.BROTLI_DECODER_RESULT_ERROR,
    success = br_c.BROTLI_DECODER_RESULT_SUCCESS,
    need_more_input = br_c.BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT,
    need_more_output = br_c.BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT,
};

pub const BrotliError = error{
    EncodeError,
    DecodeError,
};

/// brotli init
pub fn init(settings: Settings) Brotli {
    var br = Brotli{
        .settings = settings,
    };
    br.settings.encode_quality = switch (br.settings.encode_quality) {
        br_c.BROTLI_MIN_QUALITY...br_c.BROTLI_MAX_QUALITY => br.settings.encode_quality,
        else => if (br.settings.encode_quality > br_c.BROTLI_MAX_QUALITY) br_c.BROTLI_MAX_QUALITY else br_c.BROTLI_MIN_QUALITY,
    };
    br.settings.encode_window = switch (br.settings.encode_window) {
        br_c.BROTLI_MIN_WINDOW_BITS...br_c.BROTLI_MAX_WINDOW_BITS => br.settings.encode_window,
        else => if (br.settings.encode_window > br_c.BROTLI_MAX_WINDOW_BITS) br_c.BROTLI_MAX_WINDOW_BITS else br_c.BROTLI_MIN_WINDOW_BITS,
    };
    if (br.settings.decode_size_mult.len == 0) br.settings.decode_size_mult = &[_]u8{ 5, 10, 20 };
    return br;
}

/// brotli encode string
pub fn encode(self: Brotli, allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
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
        self.settings.encode_quality,
        self.settings.encode_window,
        @intFromEnum(self.settings.encode_mode),
        input.len,
        input.ptr,
        @ptrCast(&encoded_size),
        @ptrCast(encoded_buffer),
    );

    if (result == br_c.BROTLI_TRUE) {
        return try allocator.dupe(u8, encoded_buffer[0..encoded_size]);
    } else {
        log.err("Could not encode:\n{s}", .{input});
        return BrotliError.EncodeError;
    }
}

/// brotli decode string
pub fn decode(self: Brotli, allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var decoded_size: usize = 0;
    var decoded_buffer: []u8 = undefined;
    var result = brotli_decode_result.err;
    blk: for (self.settings.decode_size_mult, 0..) |mult, i| {
        // looks like that's not our 1st try..
        if (i > 0) allocator.free(decoded_buffer);

        decoded_size = input.len * mult;
        decoded_buffer = try allocator.alloc(u8, decoded_size);

        // BROTLI_DEC_API BrotliDecoderResult BrotliDecoderDecompress(
        //     size_t encoded_size,
        //     const uint8_t encoded_buffer[BROTLI_ARRAY_PARAM(encoded_size)],
        //     size_t* decoded_size,
        //     uint8_t decoded_buffer[BROTLI_ARRAY_PARAM(*decoded_size)]);
        result = @enumFromInt(br_c.BrotliDecoderDecompress(
            input.len,
            input.ptr,
            @ptrCast(&decoded_size),
            @ptrCast(decoded_buffer),
        ));
        if (result == .success) break :blk;
    }

    defer allocator.free(decoded_buffer);
    if (result == .success) {
        return try allocator.dupe(u8, decoded_buffer[0..decoded_size]);
    } else {
        log.err("{}. Could not decode with those output multipliers: {any}\n\n{s}", .{
            result,
            self.settings.decode_size_mult,
            input,
        });
        return BrotliError.DecodeError;
    }
}
