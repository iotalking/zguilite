const std = @import("std");
const truetype = @import("TrueType.zig");

fn readFile(allocator: std.mem.Allocator, fileName: []const u8) ![]u8 {
    return std.fs.cwd().readFileAlloc(allocator, fileName, 10 * 1024 * 1024);
}

pub fn main() !void {
    const argv = std.os.argv;
    if (argv.len < 4) {
        std.log.err("{s} <ttf> <text> <fontSize>", .{argv[0]});
        return;
    }

    const fontFileName = argv[1][0..std.mem.len(argv[1])];
    const textFileName = argv[2][0..std.mem.len(argv[2])];
    const fontSizeString = argv[3][0..std.mem.len(argv[3])];
    const fontHeight: usize = try std.fmt.parseInt(usize, fontSizeString, 10);
    std.log.debug("fontFileName:{s}\ntextFileName:{s}", .{ fontFileName, textFileName });
    const stdout = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const fontData = try readFile(allocator, fontFileName);
    defer allocator.free(fontData);

    const textData = try readFile(allocator, textFileName);
    defer allocator.free(textData);

    const tf = try truetype.load(fontData);
    const fontName = "KaiTi";
    // const fontHeight = 33;
    var fontCount: usize = 0;
    const scale = tf.scaleForPixelHeight(@floatFromInt(fontHeight));

    _ = try stdout.print(
        \\const guilite = @import("./guilite.zig");
        \\
    , .{});

    const StructLattice = struct {
        utf8_code: u32,
        width: u8,
    };

    const Map = std.AutoArrayHashMap(u32, StructLattice);
    var codeMap = Map.init(allocator);
    defer codeMap.deinit();
    var it = (try std.unicode.Utf8View.init(textData)).iterator();
    while (it.nextCodepoint()) |codepoint| {
        const idx = tf.codepointGlyphIndex(codepoint);
        var out = std.mem.zeroes([4]u8);
        const outLen = try std.unicode.utf8Encode(codepoint, &out);
        const utf8Code = std.mem.readVarInt(u32, out[0..outLen], .big);
        if (idx) |i| {
            _ = try stdout.print(
                \\const _{d} = [_]u8{{
                \\
            , .{utf8Code});

            var buffer: std.ArrayListUnmanaged(u8) = .{};
            defer buffer.deinit(allocator);
            const ftBitmap = try tf.glyphBitmap(allocator, &buffer, i, scale, scale);
            const pixels = buffer.items;

            var latticeData: StructLattice = .{ .utf8_code = utf8Code, .width = @truncate(ftBitmap.width) };

            var value: u8 = 0;
            var count: usize = 1;
            const x0: i16 = 0; //@as(i16, @bitCast(@abs(ftBitmap.off_x)));
            const x1 = x0 + @as(i16, @bitCast(ftBitmap.width));
            const y0: i16 = @as(i16, @truncate(@as(isize, @bitCast(fontHeight)))) - @as(i16, @bitCast(@abs(ftBitmap.off_y)));
            const y1 = y0 + @as(i16, @bitCast(ftBitmap.height));

            latticeData.width = @truncate(@as(u16, @bitCast(x1)));
            try codeMap.put(latticeData.utf8_code, latticeData);

            var writeOut = false;
            for (0..fontHeight) |y| {
                writeOut = false;

                for (0..@as(usize, @intCast(latticeData.width))) |x| {
                    var writeValue = value;
                    var writeCount = count;
                    var pixel: u8 = 0;
                    if (y >= y0 and y < y1 and x >= x0 and x < x1) {
                        const iy = y - @as(usize, @intCast(y0));
                        const ix = x - @as(usize, @intCast(x0));

                        pixel = pixels[iy * ftBitmap.width + ix];
                    } else {
                        pixel = 0;
                    }
                    if (value == pixel) {
                        count += 1;
                    } else {
                        writeOut = true;
                        writeCount = count;
                        writeValue = value;
                        value = pixel;
                        count = 1;
                    }
                    if (count >= 255) {
                        writeOut = true;
                        writeCount = count;
                        writeValue = value;
                        count = 1;
                    }
                    if (writeOut) {
                        writeOut = false;
                        try stdout.print("{d},{d},", .{
                            writeValue,
                            writeCount,
                        });
                        try stdout.writeByte('\n');
                    }
                }
            }
            _ = try stdout.print("}};\n", .{});
            fontCount += 1;
        }
    }
    _ = try stdout.print(
        \\const lattice_array = [_]guilite.LATTICE{{
        \\
    , .{});

    const C = struct {
        keys: []u32,

        pub fn lessThan(ctx: @This(), a_index: usize, b_index: usize) bool {
            return ctx.keys[a_index] < ctx.keys[b_index];
        }
    };
    codeMap.sort(C{ .keys = codeMap.keys() });
    for (codeMap.values()) |lattice| {
        _ = try stdout.print(
            \\.{{ .utf8_code = {d}, .width = {d}, .pixel_buffer = &_{d} }},
            \\
        , .{ lattice.utf8_code, lattice.width, lattice.utf8_code });
    }
    _ = try stdout.print(
        \\}};
        \\
    , .{});
    _ = try stdout.print(
        \\pub const {[fontName]s}_{[fontHeight]d}B = guilite.LatticeFontInfo{{
        \\    .height = {[fontHeight]d}, //
        \\    .count = {[count]d},
        \\    .lattice_array = &lattice_array,
        \\}};
    , .{ .fontName = fontName, .fontHeight = fontHeight, .count = fontCount });
}
