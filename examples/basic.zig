const std = @import("std");
const brotli = @import("brotli");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    defer std.debug.assert(gpa.deinit() == .ok);

    const br = brotli.init(brotli.Settings{});

    const to_encode =
        \\Hi from zig
        \\
        \\Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        \\Vestibulum ullamcorper, arcu sit amet rhoncus bibendum,
        \\purus purus pretium dolor, vel sagittis sapien risus id risus.
        \\In ligula est, scelerisque eu enim eget, ultrices luctus nunc.
        \\Quisque euismod dolor sed tempus dignissim. Fusce at imperdiet elit.
        \\Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        \\Vestibulum ullamcorper, arcu sit amet rhoncus bibendum,
        \\purus purus pretium dolor, vel sagittis sapien risus id risus.
        \\In ligula est, scelerisque eu enim eget, ultrices luctus nunc.
        \\Quisque euismod dolor sed tempus dignissim. Fusce at imperdiet elit.
        \\Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        \\Vestibulum ullamcorper, arcu sit amet rhoncus bibendum,
        \\purus purus pretium dolor, vel sagittis sapien risus id risus.
        \\In ligula est, scelerisque eu enim eget, ultrices luctus nunc.
        \\Quisque euismod dolor sed tempus dignissim. Fusce at imperdiet elit.
        \\Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        \\Vestibulum ullamcorper, arcu sit amet rhoncus bibendum,
        \\purus purus pretium dolor, vel sagittis sapien risus id risus.
        \\In ligula est, scelerisque eu enim eget, ultrices luctus nunc.
        \\Quisque euismod dolor sed tempus dignissim. Fusce at imperdiet elit.
        \\Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        \\Vestibulum ullamcorper, arcu sit amet rhoncus bibendum,
        \\purus purus pretium dolor, vel sagittis sapien risus id risus.
        \\In ligula est, scelerisque eu enim eget, ultrices luctus nunc.
        \\Quisque euismod dolor sed tempus dignissim. Fusce at imperdiet elit.
        \\Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        \\Vestibulum ullamcorper, arcu sit amet rhoncus bibendum,
        \\purus purus pretium dolor, vel sagittis sapien risus id risus.
        \\In ligula est, scelerisque eu enim eget, ultrices luctus nunc.
        \\Quisque euismod dolor sed tempus dignissim. Fusce at imperdiet elit.
        \\Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        \\Vestibulum ullamcorper, arcu sit amet rhoncus bibendum,
        \\purus purus pretium dolor, vel sagittis sapien risus id risus.
        \\In ligula est, scelerisque eu enim eget, ultrices luctus nunc.
        \\Quisque euismod dolor sed tempus dignissim. Fusce at imperdiet elit.
        \\Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        \\Vestibulum ullamcorper, arcu sit amet rhoncus bibendum,
        \\purus purus pretium dolor, vel sagittis sapien risus id risus.
        \\In ligula est, scelerisque eu enim eget, ultrices luctus nunc.
        \\Quisque euismod dolor sed tempus dignissim. Fusce at imperdiet elit.
        \\Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        \\Vestibulum ullamcorper, arcu sit amet rhoncus bibendum,
        \\purus purus pretium dolor, vel sagittis sapien risus id risus.
        \\In ligula est, scelerisque eu enim eget, ultrices luctus nunc.
        \\Quisque euismod dolor sed tempus dignissim. Fusce at imperdiet elit.
        \\Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        \\Vestibulum ullamcorper, arcu sit amet rhoncus bibendum,
        \\purus purus pretium dolor, vel sagittis sapien risus id risus.
        \\In ligula est, scelerisque eu enim eget, ultrices luctus nunc.
        \\Quisque euismod dolor sed tempus dignissim. Fusce at imperdiet elit.
        \\Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        \\Vestibulum ullamcorper, arcu sit amet rhoncus bibendum,
        \\purus purus pretium dolor, vel sagittis sapien risus id risus.
        \\In ligula est, scelerisque eu enim eget, ultrices luctus nunc.
        \\Quisque euismod dolor sed tempus dignissim. Fusce at imperdiet elit.
        \\
        \\Bye from zig
    ;
    std.debug.print("- to encode:\n{s}\n", .{to_encode});

    const encoded = try br.encode(allocator, to_encode);
    defer allocator.free(encoded);
    std.debug.print("\n- encoded:\n\n", .{});
    std.debug.print("{s} \n", .{encoded});

    const decoded = try br.decode(allocator, encoded);
    defer allocator.free(decoded);
    std.debug.print("\n- decoded:\n{s}\n", .{decoded});
}
