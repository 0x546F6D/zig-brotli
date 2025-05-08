# zig-brotli

Minimal Zig wrapper around [google/brotli](https://github.com/google/brotli) using [brotli.zig](https://github.com/0x546F6D/brotli.zig).

- example/mem_to_mem.zig performs one-shot memory to memory compression / decompression.
- example/stream.zig performs streaming compression / decompression.

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
