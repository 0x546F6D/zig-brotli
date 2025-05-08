pub const c = @cImport({
    @cInclude("brotli/decode.h");
    @cInclude("brotli/encode.h");
    @cInclude("brotli/port.h");
    @cInclude("brotli/shared_dictionary.h");
    @cInclude("brotli/types.h");
});

pub const Encoder = @import("Encoder.zig");
pub const Decoder = @import("Decoder.zig");

const std = @import("std");
