# zig-brotli

Minimal Zig wrapper around BrotliEncoderCompress() and BrotliDecoderDecompress()

## Usage

`build.zig.zon`:

```sh
zig fetch --save git+https://github.com/0x546F6D/zig-brotli
```

`build.zig`:

```zig
const opts = .{ .target = target, .optimize = optimize };
const brotli_mod = b.dependency("zig-brotli", opts).module("brotli");

exe.root_module.addImport("brotli", brotli_mod);
```
